pipeline {
agent any

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
        defaultValue: """Based only on the context provided, generate the C++ source code for a Google Test case. DO NOT include explanations, comments, or markdown wrappers. Only output the raw C++ code.""",
description: 'The coverage prompt to pass to the script.')
}

// The 'stages' block contains the logical divisions of your build process.
stages {
    stage('Iterative Coverage Improvement') {
        steps {
            script {
                def maxIterations = 3
                def iteration = 0
                def coverage = 0.0

                // Define the files used for context and requirements
                def REQUIREMENTS_FILE = './requirements.md'
                
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
                if (!fileExists(REQUIREMENTS_FILE)) {
                    writeFile file: REQUIREMENTS_FILE, text: ''
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
                
                withCredentials([string(credentialsId: 'GEMINI_API_KEY_SECRET', variable: 'GEMINI_API_KEY')]) {
                    echo "Writing requirements file..."
                    // Corrected interpolation in echo statement.
                    // echo "This is promptForRequirements: \n${promptForRequirements}"
                    
                    // Corrected interpolation in sh call using double quotes and proper variable referencing.
                    sh "python3 ai_generate_promt.py '${promptForRequirements}' '.' './requirements.md'"
                }
                
                // --- INITIAL BUILD STEP ---
                // Ensure the test executable is built before running the coverage script.
                echo "Building test executable for the first time..."
                sh 'set +x; make clean'
                sh 'set +x; make build/test_number_to_string'

                while (iteration < maxIterations) {
                    // Check if the AI-generated test file exists and create it if it doesn't.
                    def testFile = "tests/ai_generated_tests.cpp"
                    if (!fileExists(testFile)) {
                        echo "Creating empty ai_generated_tests.cpp"
                        writeFile file: testFile, text: ''
                    }

                    // Run coverage script (which executes tests internally)
                    sh './coverage.sh'

                    // --- 1. Read Coverage Data (Corrected for CPS serialization) ---
                    // The coverage.sh script places this in the 'build' directory.
                    def coverageInfoContent = readFile(file: "build/coverage.info", encoding: 'UTF-8')
                    def linesFound = 0
                    def linesHit = 0

                    // Split the content into an array of lines and iterate using a safe 'for' loop
                    def lines = coverageInfoContent.split('\n')

                    for (line in lines) {
                        if (line.startsWith("LF:")) {
                            linesFound = line.substring(3).toInteger()
                        } else if (line.startsWith("LH:")) {
                            linesHit = line.substring(3).toInteger()
                        }
                    }

                    // ... rest of your coverage calculation logic ...
                    if (linesFound > 0) {
                        coverage = (linesHit / linesFound) * 100.0
                    }

                    echo "Current coverage: ${String.format('%.2f', coverage)}%"

                    if (coverage >= 100.0) {
                        echo "Coverage is 100%. Stopping iteration."
                        break
                    }

                    // --- 2. Read Context and Requirements ---

                    def reqSpecContent = readFile(file: REQUIREMENTS_FILE, encoding: 'UTF-8')
                    def coverageReportContent = readFile(file: "coverage_report/index.html", encoding: 'UTF-8')

                    // --- 3. Assemble Final Prompt ---
                    def prompt = """${params.prompt_coverage}

                    Function Requirements Specification:
                    ${reqSpecContent}

                    Coverage Report Content:
                    ${coverageReportContent}"""

                    // --- NEW: Write the prompt to a temporary file ---
                    def outputPath = "build_${env.BUILD_NUMBER}_coverage_analysis_${iteration}.txt"
                    sh "python3 ai_generate_promt.py --prompt-file '${promptFilePath}' '${args.context_file}' '${outputPath}'"

                    // 1. Write the multi-line prompt content to a temporary file
                    // Use explicit UTF-8 encoding here to sanitize the data before writing
                    writeFile file: promptFilePath, text: prompt, encoding: 'UTF-8' 

                    withCredentials([string(credentialsId: 'GEMINI_API_KEY_SECRET', variable: 'GEMINI_API_KEY')]) {
                        echo "Analyzing coverage files, iteration ${iteration}..."
                        
                        // 2. Pass the temporary file PATH to the Python script
                        // The Python script will read the content of this file.
                        // Pass other arguments as usual.
                        // --- CORRECTED sh COMMAND ---
                        sh "python3 ai_generate_promt.py --prompt-file '${promptFilePath}' 'build/coverage.info' '${outputPath}'"
                    }

                    // --- 4. Append Generated Test Case (Enhanced Cleanup) ---

                    def rawOutput = readFile(file: outputPath, encoding: 'UTF-8')

                    // 1. Aggressive cleanup: remove AI refusals, boilerplate, and all markdown wrappers
                    // Define the pattern to look for the AI's refusal message
                    def refusalPattern = ~/(?s)As an AI, I don't have direct access to your local file system.*?\./

                    // Use replaceFirst to remove the refusal message from the raw output.
                    // The (?s) at the start of the regex enables DOTALL mode (s flag) within the pattern itself.
                    def testCaseCode = rawOutput.replaceFirst(refusalPattern, '')
                        .replaceAll(/```\s*\w*\s*/, '') // Remove opening code block
                        .replaceAll('```', '')         // Remove closing code block
                        .trim()

                    // If the resulting string is empty, the AI refused or provided no code.
                    if (testCaseCode.isEmpty()) {
                        error "AI refused the prompt or generated no code. Check the model output."
                    }

                    // Use the safe Groovy workaround for 'append'
                    def existingContent = readFile(file: testFile, encoding: 'UTF-8')
                    def newContent = existingContent + "\n" + testCaseCode
                    writeFile(file: testFile, text: newContent)

                    // Rebuild tests for next iteration (DO NOT RUN HERE)
                    echo "Rebuilding test executable..."
                    sh 'set +x; make build/test_number_to_string'

                    iteration++
                }
            }
        }
    }
}

post {
    always {
        echo "This will always run, regardless of the build status."
        sh 'set +x; make clean'
    }
}
}
