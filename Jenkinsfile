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
        defaultValue: """Create a requirements.md file from CONTEXT_FILES provided below.""",
        description: 'The console prompt to pass to the script.')
    string(
        name: 'prompt_coverage',
        defaultValue: """Provide a C++ test case source code to improve code coverage for the coverage reports in folder reports.

The tests must use the format EXPECT_EQ(expected, actual).
You must use the header file: #include "number_to_string.h".
Use the Google Test framework and the same style as test_number_to_string.cpp.
Write nothing else than code.""",
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
                def REQUIREMENTS_FILE = 'requirements.md'
                // --- DYNAMIC FILE DISCOVERY ---
                // Dynamically find all relevant source files in the 'src' directory.
                def srcFiles = findFiles(glob: 'src/**/*.{cpp,h}').collect { it.path }
                def CONTEXT_FILES = srcFiles
                // --- WRITE REQUIREMENTS FILE ---
                // Create an empty requirements file if it doesn't exist.
                if (!fileExists(REQUIREMENTS_FILE)) {
                    writeFile file: REQUIREMENTS_FILE, text: ''
                }
                // Read and concatenate the content of all context files.
                def combinedContext = ""
                CONTEXT_FILES.each { filePath ->
                    try {
                        def fileContent = readFile(file: filePath)
                        // Append content with a clear markdown header
                        combinedContext += "## File: ${filePath}\n"
                        combinedContext += "```cpp\n${fileContent}\n```\n\n"
                    } catch (FileNotFoundException e) {
                        echo "Warning: Context file not found: ${filePath}"
                    }
                }
                withCredentials([string(credentialsId: 'GEMINI_API_KEY_SECRET', variable: 'GEMINI_API_KEY')]) {
                    echo "Writing requirements file..."
                    sh "python3 ai_generate_promt.py '${params.prompt_requirements} + ${combinedContext}' './src' './requirements.md'"
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

                    // --- 1. Read Coverage Data ---
                    // The coverage.sh script places this in the 'build' directory.
                    def coverageInfoContent = readFile(file: "build/coverage.info")
                    def linesFound = 0
                    def linesHit = 0

                    // Parse LCOV file using a serializable pattern (eachLine)
                    coverageInfoContent.eachLine { line ->
                        if (line.startsWith("LF:")) {
                            linesFound = line.substring(3).toInteger()
                        } else if (line.startsWith("LH:")) {
                            linesHit = line.substring(3).toInteger()
                        }
                    }

                    if (linesFound > 0) {
                        coverage = (linesHit / linesFound) * 100.0
                    }

                    echo "Current coverage: ${String.format('%.2f', coverage)}%"

                    if (coverage >= 100.0) {
                        echo "Coverage is 100%. Stopping iteration."
                        break
                    }

                    // --- 2. Read Context and Requirements ---

                    def reqSpecContent = readFile(file: REQUIREMENTS_FILE)
                    def coverageReportContent = readFile(file: "coverage_report/index.html")

                    // --- 3. Assemble Final Prompt ---
                    def prompt = """${params.prompt_coverage}

Function Requirements Specification:
${reqSpecContent}

Coverage Report Content:
${coverageReportContent}"""

                    def outputPath = "build_${env.BUILD_NUMBER}_coverage_analysis_${iteration}.txt"

                    withCredentials([string(credentialsId: 'GEMINI_API_KEY_SECRET', variable: 'GEMINI_API_KEY')]) {
                        echo "Analyzing coverage files, iteration ${iteration}..."
                        sh "python3 ai_generate_promt.py '${prompt}' 'build/coverage.info' '${outputPath}'"
                    }

                    // --- 4. Append Generated Test Case ---

                    // Read generated test case and append to test file
                    def testCaseCode = readFile(file: outputPath).replaceAll('```cpp', '').replaceAll('```', '').trim()
                    writeFile(file: "tests/ai_generated_tests.cpp", text: testCaseCode, append: true)

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