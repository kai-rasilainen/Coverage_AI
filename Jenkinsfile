pipeline {
agent any

// ADDED: Environment block for centralized configuration
environment {
    REQUIREMENTS_FILE = './requirements.md'
    PROMPT_SCRIPT = 'ai_generate_promt.py'
    COVERAGE_SCRIPT = './coverage.sh'
    COVERAGE_INFO_FILE = 'build/coverage.info'
    COVERAGE_REPORT_HTML = 'coverage_report/index.html'
}

// Define the parameter to be passed to the script
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
        // RETAINED: Use 'string' and not 'number' due to Jenkins compatibility issues.
        name: 'min_coverage_target',
        defaultValue: '100.0', // MODIFIED: Changed default to '100.0' and is quoted as a string.
        description: 'The minimum code coverage percentage required to stop iteration.')
}

// The 'stages' block contains the logical divisions of your build process.
stages {
    stage('Iterative Coverage Improvement') {
        steps {
            script {
                // MODIFIED: Converted the utility function to a Groovy Closure (function pointer)
                def sha1 = { input ->
                    if (input == null || input.isEmpty()) return ""
                    def md = java.security.MessageDigest.getInstance("SHA-1")
                    md.update(input.getBytes("UTF-8"))
                    return new BigInteger(1, md.digest()).toString(16).padLeft(40, '0')
                }
                def maxIterations = 3
                def iteration = 0
                def coverage = 0.0

                // --- NEW STEP: VENV SETUP AND DEPENDENCY INSTALLATION ---
                echo "Setting up Python virtual environment and installing dependencies..."
                // Ensure you have python3 and venv module installed on the agent system!
                sh '''
                    # 1. Create the virtual environment in the workspace
                    python3 -m venv venv || python -m venv venv
                    
                    # 2. MODIFIED: Ensure pip executable has permissions and install directly
                    ./venv/bin/python3 -m pip install requests
                '''

                // Define the files used for context and requirements
                // REMOVED: def REQUIREMENTS_FILE = './requirements.md' // Now using env.REQUIREMENTS_FILE
                
                // --- DYNAMIC FILE DISCOVERY (FIXED GLOB PATTERN) ---
                // Dynamically find all relevant source files in the 'src' directory, recursively.

                // Use the built-in Jenkins findFiles step, which is Groovy Sandbox approved.
                // The 'glob' pattern searches for *.cpp files recursively within the 'src' directory.
                def CONTEXT_FILES_LIST = findFiles(glob: 'src/**')
                def CONTEXT_FILES = CONTEXT_FILES_LIST.findAll { 
                    // Check if the file name is NOT 'main.cpp'
                    !it.name.equals('main.cpp') &&
                    
                    // AND check if the file path ends with .cpp
                    it.path.endsWith('.cpp')
                }.collect { it.path }

                // Check for empty results and fail gracefully if no files are found.
                if (CONTEXT_FILES.isEmpty()) {
                    // You can choose to error or warn here based on if 'src' must contain files.
                    // Since the original code checked for existence, an error is appropriate if no files are found in 'src'.
                    error "Error: No .cpp files found in the 'src' directory."
                }

                echo "Context files found: ${CONTEXT_FILES}"
                
                // --- WRITE REQUIREMENTS FILE ---
                
                // Create an empty requirements file if it doesn't exist.
                if (!fileExists(env.REQUIREMENTS_FILE)) { // MODIFIED: Use env.REQUIREMENTS_FILE
                    writeFile file: env.REQUIREMENTS_FILE, text: '' // MODIFIED: Use env.REQUIREMENTS_FILE
                }
                
                // Read and concatenate the content of all context files.
                def combinedContext = ""
                CONTEXT_FILES.each { filePath ->
                    try {
                        def fileContent = readFile(file: filePath, encoding: 'UTF-8')
                        // Append content with a clear markdown header
                        combinedContext += "## File: ${filePath}\n"
                        combinedContext += "\n${fileContent}\n\n\n"
                    } catch (FileNotFoundException e) {
                        echo "Warning: Context file not found: ${filePath}"
                    }
                }
                
                // Corrected variable definition by removing illegal interpolation.
                def promptForRequirements = params.prompt_requirements + combinedContext
                
                // --- NEW: Define temp file path and write prompt content ---
                def requirementsPromptFile = "build/prompt_requirements_temp.txt"
                writeFile file: requirementsPromptFile, text: promptForRequirements, encoding: 'UTF-8' 
                
                withCredentials([string(credentialsId: 'GEMINI_API_KEY_SECRET', variable: 'GEMINI_API_KEY')]) {
                    echo "Writing requirements file..."
                    
                    // ✅ CORRECTED SH CALL: Uses the required --prompt-file flag.
                    sh """
                    # Simply call the python executable directly from the venv/bin folder.
                    ./venv/bin/python3 ${env.PROMPT_SCRIPT} --prompt-file '${requirementsPromptFile}' '.' '${env.REQUIREMENTS_FILE}'
                    """ // MODIFIED: Removed the Groovy single-line comment inside the sh block.
                }
                
                // -----------------------------------------------------------
                // --- INITIAL BUILD STEP (Updated for Makefile) ---
                // -----------------------------------------------------------
                echo "Building test executable for the first time..."

                // 1. Ensure the build directory exists
                sh 'mkdir -p build' 

                // 2. Build the test executable using the TEST_BINARY target.
                // This command will automatically run the dependencies in your Makefile.
                sh 'make build/test_number_to_string'
                // -----------------------------------------------------------

                while (iteration < maxIterations) {
                    def testFile = "tests/ai_generated_tests.cpp"
                    def testFileSave = "tests/ai_generated_tests_iter_${iteration}.txt"

                    // NEW: List to track hashes of all successful, unique tests
                    def existingTestHashes = [] 
                    
                    // NEW: Read existing tests to initialize the hash list if starting mid-run
                    if (iteration == 0 && fileExists(testFile)) {
                        def existingContent = readFile(file: testFile, encoding: 'UTF-8')
                        // A simple, quick way to split existing tests for initial hashing (requires a standardized test structure)
                        def testBlocks = existingContent.split(/(?=\nTEST\()/) 
                        testBlocks.each { block ->
                            if (block.trim().startsWith('TEST(')) {
                                existingTestHashes.add(sha1(block.trim()))
                            }
                        }
                    }
                    // --- CLEAR & SETUP: Clear the file and add necessary headers only once ---
                    echo "Preparing ai_generated_tests.cpp for iteration ${iteration}"
                    
                    // We overwrite the file in each iteration with the necessary headers/boilerplate
                    // to prevent redefinitions, and then we will read back ALL previous tests 
                    // and append the new one. This ensures we start clean every time.
                    writeFile file: testFile, text: '#include "number_to_string.h"\n#include "gtest/gtest.h"\n\n'
                    writeFile file: testFileSave, text: '#include "number_to_string.h"\n#include "gtest/gtest.h"\n\n'

                    // Run coverage script (which executes tests internally)
                    sh env.COVERAGE_SCRIPT // MODIFIED: Use env.COVERAGE_SCRIPT

                    def linesHit = 0
                    def missList = [] // NEW: List to store uncovered lines (LF: and LH: are global)
                    def currentFile = null

                    def lines = coverageInfoContent.split('\n')

                    for (line in lines) {
                        if (line.startsWith("SF:")) { // Source File
                            currentFile = line.substring(3)
                        } else if (line.startsWith("LF:")) {
                            linesFound = line.substring(3).toInteger()
                        } else if (line.startsWith("LH:")) {
                            linesHit = line.substring(3).toInteger()
                        } else if (line.startsWith("DA:") && line.endsWith(',0')) { // Data line with 0 hits
                            def parts = line.substring(3).split(',')
                            def lineNumber = parts[0]
                            def functionName = "" 
                            
                            // Optional: Try to find function name above the uncovered line 
                            // This is complex, so for simplicity, we just list the line number
                            missList.add("File: ${currentFile} Line: ${lineNumber} (Uncovered)")
                        }
                    }
                    
                    def missListContent = missList.join('\n')
                    echo "Uncovered lines found:\n${missListContent}"

                    // ... rest of your coverage calculation logic ...
                    if (linesFound > 0) {
                        coverage = (linesHit / linesFound) * 100.0
                    }

                    echo "Current coverage: ${String.format('%.2f', coverage)}%"

                    // MODIFIED: Use the string parameter converted to Float for comparison
                    if (coverage >= params.min_coverage_target.toFloat()) {
                        echo "Coverage is ${String.format('%.2f', coverage)}% which meets the target of \
                        ${params.min_coverage_target}%. Stopping iteration."
                        break
                    }

                    // --- 2. Read Context and Requirements ---

                    def reqSpecContent = readFile(file: env.REQUIREMENTS_FILE, encoding: 'UTF-8') // MODIFIED: Use env.REQUIREMENTS_FILE
                    def coverageReportContent = readFile(file: env.COVERAGE_REPORT_HTML, encoding: 'UTF-8') // MODIFIED: Use env.COVERAGE_REPORT_HTML
 
                     // --- 3. Assemble Final Prompt ---
                    // NOTE: Removed env.COVERAGE_REPORT_HTML content. Using the new missListContent is better.
                    
                    // NEW: TARGETED CONTEXT (I.3)
                    // If missList is empty, there is no need to prompt the model. The break condition should handle it.
                    // If you want to ONLY send the relevant source file content:
                    def relevantSourceContent = ""
                    // For this simple example, we assume we only care about number_to_string.cpp/h
                    CONTEXT_FILES.each { filePath ->
                        if (filePath.contains('number_to_string')) {
                            def fileContent = readFile(file: filePath, encoding: 'UTF-8')
                            relevantSourceContent += "## Relevant Source File: ${filePath}\n\n${fileContent}\n\n\n"
                        }
                    }

                    def prompt = """${params.prompt_coverage}
                        Function Requirements Specification:
                        ${reqSpecContent}
                        
                        ---
                        
                        Uncovered Code Paths (Miss List):
                        ${missListContent}
                        
                        ---
                        
                        Relevant Source Code:
                        ${relevantSourceContent}""" // Use targeted content

                    // --- Variable Definitions and File Setup (Defined FIRST) ---
                    def outputPath = "build_${env.BUILD_NUMBER}_coverage_analysis_${iteration}.txt"
                    def promptFilePath = "build/prompt_content_iter_${iteration}.txt"
                    def contextFilePath = env.COVERAGE_INFO_FILE // MODIFIED: Use env.COVERAGE_INFO_FILE

                    // 1. Write the multi-line prompt content to the temporary file (MUST BE BEFORE 'sh')
                    writeFile file: promptFilePath, text: prompt, encoding: 'UTF-8' 

                    withCredentials([string(credentialsId: 'GEMINI_API_KEY_SECRET', variable: 'GEMINI_API_KEY')]) {
                        echo "Analyzing coverage files, iteration ${iteration}..."
                        
                        // 2. Call the Python script with all required arguments.
                        // Structure: --prompt-file <path> <context_file> <output_file>
                        sh """
                        # Simply call the python executable directly from the venv/bin folder.
                        ./venv/bin/python3 ${env.PROMPT_SCRIPT} --prompt-file '${promptFilePath}' '${contextFilePath}' '${outputPath}'
                        """ // MODIFIED: Removed the Groovy single-line comment inside the sh block.
                    }

                    // --- 4. Append Generated Test Case (Corrected Cleanup) ---

                    def rawOutput = readFile(file: outputPath, encoding: 'UTF-8')

                    // Use a simple String for the refusal text to match the safest method signature,
                    // or use replaceAll with the Groovy regex pattern. replaceAll is often whitelisted.
                    def testCaseCode = rawOutput
                        // Use replaceAll with the Groovy regex syntax. This is more likely to be whitelisted
                        // than the replaceFirst signature.
                        .replaceAll(/(?s)As an AI, I don't have direct access to your local file system.*?\./, '') 
                        .replaceAll(/```\s*\w*\s*/, '') // Remove opening code block
                        .replaceAll('```', '')         // Remove closing code block
                        .trim()

                    // If the resulting string is empty, the AI refused or provided no code.
                    if (testCaseCode.isEmpty()) {
                        error "AI refused the prompt or generated no code. Check the model output."
                    }

                    // --- NEW: Test Debouncing/Uniqueness Check (I.2) ---
                    def newTestHash = sha1(testCaseCode)
                    
                    if (existingTestHashes.contains(newTestHash)) {
                        echo "Warning: Generated test case is identical (hash: ${newTestHash}). Skipping rebuild and next iteration."
                        // Do NOT increment iteration here; break or continue to next iteration without rebuilding tests
                        // We will just 'continue' to the top of the loop to re-check coverage and potentially stop/re-prompt
                        continue
                    }
                    
                    // If unique, add to the tracking list
                    existingTestHashes.add(newTestHash)
                    echo "New unique test case generated (hash: ${newTestHash}). Appending and rebuilding."

                    // If testFile exists, readFile will get the old tests (if any)
                    def existingContent = readFile(file: testFile, encoding: 'UTF-8')
                    def existingContentSave = readFile(file: testFileSave, encoding: 'UTF-8')
                 
                    // Combine old content with new, cleaned test case code
                    def newContent = existingContent + "\n" + testCaseCode
                    def newContentSave = existingContentSave + "\n" + testCaseCode
              
                    // Overwrite the file with ALL cumulative tests.
                    writeFile(file: testFile, text: newContent)
                    writeFile(file: testFileSave, text: newContentSave)

                    // Rebuild tests for next iteration (DO NOT RUN HERE)
                    echo "Rebuilding test executable..."
                    // Only run the target build command.
                    sh 'make build/test_number_to_string'
                    // ----------------------------------------------------

                    iteration++
                }
            }
        }
    }
}

post {
    always {
      
  echo "This will always run, regardless of the build status."
    // Clean up using the Makefile's defined target
        // WRAP THE SH STEP IN A 'script' BLOCK TO ENSURE IT'S EXECUTED CORRECTLY
        script {
            sh 'make clean' 
        }
    }
}
}