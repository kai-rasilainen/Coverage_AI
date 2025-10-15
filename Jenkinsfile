pipeline {
agent any

// Environment variables centralize configuration paths
environment {
    REQUIREMENTS_FILE = './requirements.md'
    PROMPT_SCRIPT = 'ai_generate_promt.py'
    COVERAGE_SCRIPT = './coverage.sh'
    COVERAGE_INFO_FILE = 'build/coverage.info'
    COVERAGE_REPORT_HTML = 'coverage_report/index.html'
}

parameters {
    string(
        name: 'prompt_console',
        defaultValue: """Read Jenkins console output file and provide a detailed analysis of its content. Write your analysis in a clear and structured manner.""",
        description: 'The console prompt to pass to the script.')
    string(
        name: 'prompt_requirements',
        defaultValue: """Create a simple requirements.md file from source code provided below. Focus only for the unit tests.""",
        description: 'The console prompt to pass to the script.')
    string(
        name: 'prompt_coverage',
        defaultValue: """Based only on the context provided, generate the C++ source code for a Google Test case.
The test code must use the format EXPECT_EQ(expected, actual).
You must use the header file: #include "number_to_string.h".
DO NOT include any supporting class or struct definitions (like NumberGroup).
DO NOT include any headers (like iostream or gtest).
DO NOT include explanations, comments, or markdown wrappers.
Only output the raw C++ code for the test function.""",
description: 'The coverage prompt to pass to the script.')
    string(
        name: 'min_coverage_target',
        defaultValue: '100.0',
        description: 'The minimum code coverage percentage required to stop iteration.')
}

stages {
    stage('Iterative Coverage Improvement') {
        steps {
            script {
                // UTILITY CLOSURE: Hashing function for test debouncing (Requires approval)
                def sha1 = { input ->
                    if (input == null || input.isEmpty()) return ""
                    def md = java.security.MessageDigest.getInstance("SHA-1")
                    md.update(input.getBytes("UTF-8"))
                    return new BigInteger(1, md.digest()).toString(16).padLeft(40, '0')
                }
                
                // --- VARIABLE INITIALIZATION ---
                def maxIterations = 3
                def iteration = 0
                def coverage = 0.0
                def existingTestHashes = [] 
                def CONTEXT_FILES = [] // All C++ files found in src/
                
                // Variables used by the LCOV parsing logic
                def coverageInfoContent = '' 
                def linesFound = 0
                def linesHit = 0
                def missList = []
                def currentFile = null
                
                // --- VENV SETUP AND DEPENDENCY INSTALLATION ---
                echo "Setting up Python virtual environment and installing dependencies..."
                sh '''
                    # 1. Create the virtual environment in the workspace
                    python3 -m venv venv || python -m venv venv
                    
                    # 2. MODIFIED: Install all required Python packages for AI and RAG
                    ./venv/bin/python3 -m pip install requests google-genai chromadb
                '''
                
                // --- DYNAMIC FILE DISCOVERY AND CONTEXT AGGREGATION ---
                echo "Discovering context files and aggregating source code..."

                def CONTEXT_FILES_LIST = findFiles(glob: 'src/**')
                CONTEXT_FILES = CONTEXT_FILES_LIST.findAll { 
                    !it.name.equals('main.cpp') && it.path.endsWith('.cpp')
                }.collect { it.path }
                
                if (CONTEXT_FILES.isEmpty()) {
                    error "Error: No .cpp files found in the 'src' directory."
                }

                // CONSOLIDATED: Build combinedContext ONCE for requirements generation
                def combinedContext = ""
                CONTEXT_FILES.each { filePath ->
                    try {
                        def fileContent = readFile(file: filePath, encoding: 'UTF-8')
                        combinedContext += "## File: ${filePath}\n\n${fileContent}\n\n\n"
                    } catch (FileNotFoundException e) {
                        echo "Warning: Context file not found: ${filePath}"
                    }
                }
                echo "Context files found: ${CONTEXT_FILES}"

                // --- REQUIREMENTS FILE GENERATION ---
                if (!fileExists(env.REQUIREMENTS_FILE)) { 
                    writeFile file: env.REQUIREMENTS_FILE, text: ''
                }
                
                def promptForRequirements = params.prompt_requirements + combinedContext
                def requirementsPromptFile = "build/prompt_requirements_temp.txt"
                writeFile file: requirementsPromptFile, text: promptForRequirements, encoding: 'UTF-8' 
                
                withCredentials([string(credentialsId: 'GEMINI_API_KEY_SECRET', variable: 'GEMINI_API_KEY')]) {
                    echo "Writing requirements file..."
                    sh """
                    ./venv/bin/python3 ${env.PROMPT_SCRIPT} --prompt-file '${requirementsPromptFile}' '.' '${env.REQUIREMENTS_FILE}'
                    """
                }
                
                // --- INITIAL BUILD AND HASH SETUP ---
                echo "Building test executable for the first time..."
                sh 'mkdir -p build' 
                sh 'make build/test_number_to_string' // Assuming this is the desired initial build target
                
                // Load existing test hashes once before the loop
                def testFile = "tests/ai_generated_tests.cpp"
                if (fileExists(testFile)) {
                    echo "Initializing hash list from existing tests..."
                    def existingContent = readFile(file: testFile, encoding: 'UTF-8')
                    def testBlocks = existingContent.split(/(?=\nTEST\()/) 
                    testBlocks.each { block ->
                        if (block.trim().startsWith('TEST(')) {
                            existingTestHashes.add(sha1(block.trim()))
                        }
                    }
                }
                // -----------------------------------------------------------
                // --- RAG STEP 1: INDEXING THE CODEBASE ---
                echo "Indexing codebase for Semantic Search..."
                def contextFilesString = CONTEXT_FILES.join(' ')
                
                withCredentials([string(credentialsId: 'GEMINI_API_KEY_SECRET', variable: 'GEMINI_API_KEY')]) {
                    sh """
                    # Note: You need 'chromadb' installed in your venv for this to work.
                    ./venv/bin/python3 rag_context_finder.py index --files ${contextFilesString}
                    """
                }
                // ----------------------------------------

                while (iteration < maxIterations) {
                    def testFileSave = "tests/ai_generated_tests_iter_${iteration}.txt"
                    
                    // --- CLEAR & SETUP ---
                    echo "Preparing ai_generated_tests.cpp for iteration ${iteration}"
                    writeFile file: testFile, text: '#include "number_to_string.h"\n#include "gtest/gtest.h"\n\n'
                    writeFile file: testFileSave, text: '#include "number_to_string.h"\n#include "gtest/gtest.h"\n\n'

                    // Run coverage script
                    sh env.COVERAGE_SCRIPT 

                    // --- LCOV PARSING AND MISS LIST GENERATION ---
                    coverageInfoContent = readFile(file: env.COVERAGE_INFO_FILE, encoding: 'UTF-8')
                    linesFound = 0
                    linesHit = 0
                    missList = [] 
                    currentFile = null
                    
                    def functionMissMap = [:] // Used for targeted context (I.1)
                    def lines = coverageInfoContent.split('\n')

                    for (line in lines) {
                        if (line.startsWith("SF:")) { 
                            currentFile = line.substring(3)
                        } else if (line.startsWith("FN:")) { // Function Name definition
                            def parts = line.substring(3).split(',')
                            functionMissMap[parts[1]] = [file: currentFile, startLine: parts[0], hits: 0]
                        } else if (line.startsWith("FNDA:") && line.endsWith(',0')) { // Function hit data (0 hits)
                            def functionName = line.substring(5).split(',')[1]
                            if (functionMissMap.containsKey(functionName)) {
                                functionMissMap[functionName].hits = 0
                            }
                        } else if (line.startsWith("DA:") && line.endsWith(',0')) { // Data line with 0 hits
                            def lineNumber = line.substring(3).split(',')[0]
                            missList.add("File: ${currentFile} Line: ${lineNumber} (Uncovered)")
                        }
                        if (line.startsWith("LF:")) { linesFound = line.substring(3).toInteger() }
                        if (line.startsWith("LH:")) { linesHit = line.substring(3).toInteger() }
                    }
                    
                    // --- TARGET SELECTION AND PROMPT ASSEMBLY (I.1/I.3) ---
                    def targetFunction = null
                    functionMissMap.each { name, data ->
                        if (data.hits == 0) {
                            targetFunction = data
                            return
                        }
                    }

                    def relevantSourceContent = ""
                    def targetName = "uncovered lines listed below"
                    
                    if (targetFunction) {
                        targetName = "${targetFunction.name} in ${targetFunction.file}"
                        echo "AI Target: Focusing on completely missed function: ${targetName}"
                        
                        // Extract target file content (Optimization I.3)
                        CONTEXT_FILES.each { filePath ->
                            if (filePath == targetFunction.file) {
                                relevantSourceContent = "## Target Function: ${targetFunction.name} in File: ${filePath}\n\n${readFile(file: filePath, encoding: 'UTF-8')}\n\n\n"
                                return // Optimization: break CONTEXT_FILES loop
                            }
                        }
                    } else {
                        echo "No completely missed functions found. Using all existing context."
                    }
                    
                    def missListContent = missList.join('\n')
                    
                    // --- RAG STEP 2: RETRIEVE CONTEXT ---
                    def retrievalQuery = "Uncovered lines requiring a new test case:\n${missListContent}"
                    def retrievedContextFile = "build/rag_context_iter_${iteration}.txt"
                    
                    withCredentials([string(credentialsId: 'GEMINI_API_KEY_SECRET', variable: 'GEMINI_API_KEY')]) {
                        sh """
                        ./venv/bin/python3 rag_context_finder.py retrieve \\
                            --query "${retrievalQuery}" \\
                            --output "${retrievedContextFile}"
                        """
                    }
                    
                    def retrievedSourceContent = readFile(file: retrievedContextFile, encoding: 'UTF-8')
                    echo "Retrieved source context size: ${retrievedSourceContent.length()} characters."
                    // ------------------------------------

                    def reqSpecContent = readFile(file: env.REQUIREMENTS_FILE, encoding: 'UTF-8')
                    
                    // --- 3. Assemble Final Prompt (Use Retrieved Content) ---
                    def prompt = """${params.prompt_coverage}
                        
                        **GOAL: Generate a test case that achieves coverage for the function: ${targetName}.**
                        
                        Function Requirements Specification:
                        ${reqSpecContent}
                        
                        ---
                        
                        Uncovered Code Paths (Miss List):
                        ${missListContent}
                        
                        ---
                        
                        Relevant Source Code (Retrieved by RAG):
                        ${retrievedSourceContent}""" // MODIFIED: Use the retrieved content!

                    def outputPath = "build_${env.BUILD_NUMBER}_coverage_analysis_${iteration}.txt"
                    def promptFilePath = "build/prompt_content_iter_${iteration}.txt"
                    writeFile file: promptFilePath, text: prompt, encoding: 'UTF-8' 

                    withCredentials([string(credentialsId: 'GEMINI_API_KEY_SECRET', variable: 'GEMINI_API_KEY')]) {
                        echo "Analyzing coverage files, iteration ${iteration}..."
                        sh """
                        ./venv/bin/python3 ${env.PROMPT_SCRIPT} --prompt-file '${promptFilePath}' '${env.COVERAGE_INFO_FILE}' '${outputPath}'
                        """ 
                    }

                    // --- TEST GENERATION AND DEBOUNCING (I.2) ---
                    def rawOutput = readFile(file: outputPath, encoding: 'UTF-8')

                    def testCaseCode = rawOutput
                        .replaceAll(/(?s)As an AI, I don't have direct access to your local file system.*?\./, '') 
                        .replaceAll(/```\s*\w*\s*/, '')
                        .replaceAll('```', '')
                        .trim()

                    if (testCaseCode.isEmpty()) {
                        error "AI refused the prompt or generated no code. Check the model output."
                    }

                    def newTestHash = sha1(testCaseCode) 
                    
                    if (existingTestHashes.contains(newTestHash)) {
                        echo "Warning: Generated test case is identical (hash: ${newTestHash}). Skipping rebuild and next iteration."
                        continue
                    }
                    
                    existingTestHashes.add(newTestHash)
                    echo "New unique test case generated (hash: ${newTestHash}). Appending and rebuilding."

                    def existingContent = readFile(file: testFile, encoding: 'UTF-8')
                    def existingContentSave = readFile(file: testFileSave, encoding: 'UTF-8')
                    
                    def newContent = existingContent + "\n" + testCaseCode
                    def newContentSave = existingContentSave + "\n" + testCaseCode
                    
                    writeFile(file: testFile, text: newContent)
                    writeFile(file: testFileSave, text: newContentSave)

                    echo "Rebuilding test executable..."
                    sh 'make build/test_number_to_string'

                    iteration++
                }
            }
        }
    }
}

post {
    always {
        echo "This will always run, regardless of the build status."
        
        // --- ARTIFACT ARCHIVAL (II.2) ---
        archiveArtifacts artifacts: """
            ${env.REQUIREMENTS_FILE},
            tests/ai_generated_tests.cpp,
            ${env.COVERAGE_INFO_FILE}
        """
        archiveArtifacts artifacts: 'coverage_report/**', allowEmptyArchive: true
        
        // --- CLEANUP ---
        script {
            sh 'make clean' 
        }
    }
}
}