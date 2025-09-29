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
        defaultValue: """Write a requirements.md file based on /src/* folder content. Resulting file is used to improve test cases. Write your analysis in a clear and structured manner.""",
        description: 'The console prompt to pass to the script.')

    string(
        name: 'prompt_coverage',
        // NOTE: The default value is now a generalized instruction for the AI 
        // to follow the specification included below in the prompt.
        defaultValue: """Analyze the provided Function Requirements Specification (below) and the Coverage Report to generate a C++ test case.

Use the Google Test framework and the same style as test_number_to_string.cpp.
The function to test is numberToString.
The tests must use the format EXPECT_EQ(expected, actual).
You must use the header file: #include "number_to_string.h".
Write nothing else than code.""",
description: 'The coverage prompt to pass to the script.')
}

// The 'stages' block contains the logical divisions of your build process.
stages {
    stage('Create Requirements Specification') {
        steps {
            script {
                // --- PREPARE PROMPT ---
                // Ensure the prompt uses one set of triple quotes for the multi-line string.
                def prompt = """${params.prompt_requirements}"""

                withCredentials([string(credentialsId: 'GEMINI_API_KEY_SECRET', variable: 'GEMINI_API_KEY')]) {
                        echo "Creating requirements file..."
                        sh "python3 ai_generate_promt.py '${prompt}' 'src/*' './requirements.md'"
                }
            }
        }
    }

    stage('Iterative Coverage Improvement') {
        steps {
            script {
                // --- VARIABLE DEFINITION MOVED HERE ---
                // Groovy requires 'def' outside of a stage to be in an environment block,
                // but inside the 'script' block is simpler for local variables.
                def REQUIREMENTS_FILE = 'requirements.md'

                // --- INITIAL BUILD STEP ---
                echo "Building test executable for the first time..."
                sh 'make clean'
                sh 'make build/test_number_to_string'

                // --- LOAD REQUIREMENTS SPECIFICATION ---
                // This dynamically loads the specification from the external file.
                def reqSpecContent = ""
                if (fileExists(REQUIREMENTS_FILE)) {
                    reqSpecContent = readFile(file: REQUIREMENTS_FILE)
                    echo "Loaded requirements from ${REQUIREMENTS_FILE}."
                } else {
                    error "Fatal Error: Requirements file ${REQUIREMENTS_FILE} not found. Cannot proceed."
                }

                // The rest of the pipeline is now in a loop for iterative improvement
                def maxIterations = 3
                def iteration = 0
                def coverage = 0.0

                while (iteration < maxIterations) {
                    // Check if the AI-generated test file exists and create it if it doesn't.
                    def testFile = "tests/ai_generated_tests.cpp"
                    if (!fileExists(testFile)) {
                        echo "Creating empty ai_generated_tests.cpp"
                        writeFile file: testFile, text: ''
                    }

                    // Run coverage script (CLEAN -> RUN -> CAPTURE)
                    sh 'set +x; ./coverage.sh'

                    // Read the coverage report to get the percentage
                    def coverageInfoContent = readFile(file: "build/coverage.info")
                    def linesFound = 0
                    def linesHit = 0

                    // Parse LCOV file for Lines Found and Lines Hit
                    // Uses the serializable Groovy pattern.
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

                    // --- DEFENSIVE CHECK for HTML ---
                    def coverageReportFile = "coverage_report/index.html"
                    def coverageReportContent = ""
                    if (fileExists(coverageReportFile)) {
                        coverageReportContent = readFile(file: coverageReportFile)
                    } else {
                        echo "WARNING: HTML coverage report '${coverageReportFile}' was not found. Using LCOV data only."
                        coverageReportContent = "HTML report not found. See LCOV report for coverage data."
                    }

                    // --- PREPARE FINAL PROMPT (NOW INCLUDING REQUIREMENTS) ---
                    // Ensure the prompt uses one set of triple quotes for the multi-line string.
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

                    // Read generated test case and append to test file
                    def testCaseCode = readFile(file: outputPath).replaceAll('```cpp', '').replaceAll('```', '').trim()
                    writeFile(file: "tests/ai_generated_tests.cpp", text: testCaseCode, append: true)

                    // Rebuild tests for next iteration (DO NOT RUN HERE)
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
        sh 'make clean'
    }
}

}