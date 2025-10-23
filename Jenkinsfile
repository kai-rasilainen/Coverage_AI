// 1. TOP-LEVEL SCRIPT BLOCK
script {
    node('master') { 
        
        // --- CRITICAL FIX: CLEANUP VENV BEFORE ANY GIT OPERATION ---
        // 1. Fix ownership of the whole workspace (in case 'jenkins' user can't delete 'kai' files)
        sh 'sudo chown -R jenkins:jenkins /var/lib/jenkins/workspace/Coverage_AI || true' 
        
        // 2. Delete the persistent, permission-locked venv folder
        sh 'rm -rf venv || true'
        // -----------------------------------------------------------

        // Now that the venv is gone, Git can safely check out the source code
        checkout scm 

        // Load the Groovy file
        def paramsLoader = load 'pipeline-parameters.groovy'

        // Call the function to get the array of parameters.
        def externalParams = paramsLoader.getParams()

        // Use the 'properties' step to apply the parameters list to the job configuration.
        properties([
            parameters(externalParams)
        ])
    }
}
// END OF TOP-LEVEL SCRIPT BLOCK

pipeline {
    agent any

    // We assume the SCM is now handled by the external script block and no implicit
    // checkout will happen at the start of the 'pipeline' block.
    // If Git checkout still fails, you MUST configure the job to only run checkout once,
    // usually by disabling the SCM setting on the pipeline itself, or using the 
    // "Do not skip default checkout" option.

    // Environment variables centralize configuration paths
    environment {
        REQUIREMENTS_FILE = './requirements.md'
        PROMPT_SCRIPT = 'ai_generate_promt.py'
        COVERAGE_SCRIPT = './coverage.sh'
        COVERAGE_INFO_FILE = 'build/coverage.info'
        COVERAGE_REPORT_HTML = 'coverage_report/index.html'
    }

    stages {
        stage('Iterative Coverage Improvement') {
            steps {
                script {
                    // **CRITICAL FIX: REMOVE REDUNDANT CLEANUP HERE**
                    // The venv cleanup has been moved to the external script block 
                    // before the initial 'checkout scm'.
                    // The following two lines are now commented out/removed:
                    // sh 'sudo chown -R jenkins:jenkins /var/lib/jenkins/workspace/Coverage_AI || true' 
                    // sh 'rm -rf venv'

                    // --- LOAD UTILITIES ---
                    def sha1 = load 'sha1Utils.groovy'
                    
                    // --- VARIABLE INITIALIZATION ---
                    def maxIterations = 3
                    def iteration = 0
                    def coverage = 0.0
                    def existingTestHashes = [] 
                    def CONTEXT_FILES = [] 
                    
                    // 🆕 FIX: Ensure the script is executable before running it
                    sh 'chmod +x setup_env.sh'
                    
                    // --- VENV SETUP AND DEPENDENCY INSTALLATION ---
                    sh './setup_env.sh' 
                    
                    // ... rest of your original script logic ...
                    // All other logic remains the same, as the errors were environment-related.
                    
                    // --- DYNAMIC FILE DISCOVERY AND CONTEXT AGGREGATION ---
                    echo "Discovering context files and aggregating source code..."

                    def CONTEXT_FILES_LIST = findFiles(glob: 'src/**')
                    // Assignment to pre-defined variable
                    CONTEXT_FILES = CONTEXT_FILES_LIST.findAll { 
                        !it.name.equals('main.cpp') && it.path.endsWith('.cpp')
                    }.collect { it.path }
                    
                    if (CONTEXT_FILES.isEmpty()) {
                        error "Error: No .cpp files found in the 'src' directory."
                    }

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
                    sh 'make build/test_number_to_string'
                    
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
                    
                    // --- RAG INDEXING (MOVED HERE FOR OPTIMIZATION) ---
                    echo "Indexing codebase for Semantic Search (RAG)..."
                    def contextFilesString = CONTEXT_FILES.join(' ')
                    
                    withCredentials([string(credentialsId: 'GEMINI_API_KEY_SECRET', variable: 'GEMINI_API_KEY')]) {
                        sh """
                        ./venv/bin/python3 rag_context_finder.py index --files ${contextFilesString}
                        """
                    }
                    // ---------------------------------------------------

                    while (iteration < maxIterations) {
                        def testFileSave = "tests/ai_generated_tests_iter_${iteration}.txt"
                        
                        // --- CLEAR & SETUP ---
                        echo "Preparing ai_generated_tests.cpp for iteration ${iteration}"
                        writeFile file: testFile, text: '#include "number_to_string.h"\n#include "gtest/gtest.h"\n\n'
                        writeFile file: testFileSave, text: '#include "number_to_string.h"\n#include "gtest/gtest.h"\n\n'

                        // --- LOAD PARSER UTILITY ---
                        def lcovParser = null // Explicitly initialize to null
                        if (fileExists('lcovParser.groovy')) {
                            lcovParser = load 'lcovParser.groovy'
                            
                            // Check if the load operation was successful
                            if (lcovParser == null) {
                                error "FATAL: 'lcovParser.groovy' found but 'load' step returned a null object. Check the external script's syntax."
                            }
                        } else {
                            error "FATAL: Required utility file 'lcovParser.groovy' not found in workspace."
                        }

                        // Run coverage script
                        sh env.COVERAGE_SCRIPT 

                        // --- LCOV PARSING AND MISS LIST GENERATION (I.1) ---
                        // Note: We pass 'this' (the current Script binding) to allow the parser 
                        // to use Jenkins steps like readFile.
                        def parseResult = lcovParser(this, env.COVERAGE_INFO_FILE)

                        // Extract the required variables from the returned map
                        def linesFound = parseResult.linesFound
                        def linesHit = parseResult.linesHit
                        def missList = parseResult.missList 
                        def functionMissMap = parseResult.functionMissMap
                        
                        // --- TARGET SELECTION AND RAG RETRIEVAL (I.1/I.3/2.A) ---
                        def targetFunction = null
                        functionMissMap.each { name, data ->
                            if (data.hits == 0) {
                                targetFunction = data
                                return
                            }
                        }

                        def reqSpecContent = readFile(file: env.REQUIREMENTS_FILE, encoding: 'UTF-8')
                        def targetName = "uncovered lines listed below"
                        
                        // RAG Retrieval Query (I.3/2.A)
                        def retrievalQuery = "Uncovered lines requiring a new test case:\n${missList.join('\n')}"
                        def retrievedContextFile = "build/rag_context_iter_${iteration}.txt"
                        
                        withCredentials([string(credentialsId: 'GEMINI_API_KEY_SECRET', variable: 'GEMINI_API_KEY')]) {
                            sh """
                            ./venv/bin/python3 rag_context_finder.py retrieve \\
                                --query "${retrievalQuery}" \\
                                --output "${retrievedContextFile}"
                            """
                        }
                        
                        def retrievedSourceContent = readFile(file: retrievedContextFile, encoding: 'UTF-8')
                        def relevantSourceContent = retrievedSourceContent // Start with RAG result

                        // Fallback to simpler target name/content if RAG fails or target is null
                        if (targetFunction) {
                            targetName = "${targetFunction.name} in ${targetFunction.file}"
                            echo "AI Target: Focusing on completely missed function: ${targetName}"
                        } else {
                            echo "No completely missed functions found. Using RAG context."
                        }
                        
                        def missListContent = missList.join('\n')

                        // --- PROMPT COMPRESSION CHECK (3.A/3.B) ---
                        def RAW_CONTEXT = relevantSourceContent 
                        def MAX_CHAR_THRESHOLD = 1000 
                        def FINAL_CONTEXT = RAW_CONTEXT

                        echo "Raw context size: ${RAW_CONTEXT.length()} characters."

                        if (RAW_CONTEXT.length() > MAX_CHAR_THRESHOLD) {
                            echo "Context too large (${RAW_CONTEXT.length()} chars). Summarizing..."
                            def rawContextTempFile = "build/raw_context_iter_${iteration}.txt"
                            def rawContextTempFileSave = "raw_context_iter_${iteration}.txt"
                            writeFile file: rawContextTempFile, text: RAW_CONTEXT, encoding: 'UTF-8'
                            writeFile file: rawContextTempFileSave, text: RAW_CONTEXT, encoding: 'UTF-8' 
                            
                            def summarizedContextFile = "build/summarized_context_iter_${iteration}.txt"
                            def summarizedContextFileSave = "summarized_context_iter_${iteration}.txt"

                            withCredentials([string(credentialsId: 'GEMINI_API_KEY_SECRET', variable: 'GEMINI_API_KEY')]) {
                                sh """
                                ./venv/bin/python3 summarize_code.py '${rawContextTempFile}' '${summarizedContextFile}'
                                """ 
                            }
                            
                            FINAL_CONTEXT = readFile(file: summarizedContextFile, encoding: 'UTF-8')
                            writeFile file: summarizedContextFileSave, text: FINAL_CONTEXT, encoding: 'UTF-8'
                            echo "Summary size: ${FINAL_CONTEXT.length()} characters."
                        }

                        // --- COVERAGE CHECK ---
                        if (linesFound > 0) {
                            coverage = (linesHit / linesFound) * 100.0
                        }
                        echo "Current coverage: ${String.format('%.2f', coverage)}%"

                        if (coverage >= params.min_coverage_target.toFloat()) {
                            echo "Coverage is ${String.format('%.2f', coverage)}% which meets the target of ${params.min_coverage_target}%. Stopping iteration."
                            break
                        }

                        // --- ASSEMBLE FINAL PROMPT ---
                        def prompt = """${params.prompt_coverage}
                            
                            **GOAL: Generate a test case that achieves coverage for the function: ${targetName}.**
                            
                            Function Requirements Specification:
                            ${reqSpecContent}
                            
                            ---
                            
                            Uncovered Code Paths (Miss List):
                            ${missListContent}
                            
                            ---
                            
                            Relevant Source Code:
                            ${FINAL_CONTEXT}""" // Use the compressed context

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