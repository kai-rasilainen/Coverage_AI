pipeline {
agent any

// Define the parameter to be passed to the script
parameters {
    string(
        name: 'prompt_console',
        defaultValue: """Read Jenkins console output file and provide a detailed analysis of its content. Write your analysis in a clear and structured manner.""",
        description: 'The console prompt to pass to the script.')

    string(
        name: 'prompt_coverage',
        defaultValue: """Provide a C++ test case source code to improve code coverage for the coverage reports in folder reports. Use the Google Test framework and the same style as test_number_to_string.cpp. You MUST use the header file: #include "number_to_string.h", NOT "ai_created_test_case.h". Write nothing else than code. """,
        description: 'The coverage prompt to pass to the script.')
}

// The 'stages' block contains the logical divisions of your build process.
stages {
    stage('Iterative Coverage Improvement') {
        steps {
            script {
                // --- INITIAL BUILD STEP ---
                // This step is crucial to ensure the test executable exists
                // before the coverage script tries to run it.
                echo "Building and running tests for the first time..."
                sh 'make test'

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

                    // Run coverage script to update reports
                    sh './coverage.sh'

                    // Read the coverage report to get the percentage
                    // The coverage.sh script places this in the 'build' directory.
                    def coverageInfoContent = readFile(file: "build/coverage.info")
                    def linesFound = 0
                    def linesHit = 0

                    // Parse LCOV file for Lines Found and Lines Hit
                    // This uses a different approach to avoid the NotSerializableException.
                    def lineMatcher = (coverageInfoContent =~ /^(LF|LH):([0-9]+)$/)
                    lineMatcher.each { match ->
                        if (match[1] == 'LF') {
                            linesFound = match[2].toInteger()
                        } else if (match[1] == 'LH') {
                            linesHit = match[2].toInteger()
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

                    // Prepare prompt for Gemini
                    // Use the prompt_coverage parameter and append the coverage report content.
                    // The index.html is in the 'coverage_report' directory.
                    def coverageReportContent = readFile(file: "coverage_report/index.html")
                    def prompt = "${params.prompt_coverage}\n\nCoverage Report Content:\n${coverageReportContent}"

                    def outputPath = "build_${env.BUILD_NUMBER}_coverage_analysis_${iteration}.txt"

                    withCredentials([string(credentialsId: 'GEMINI_API_KEY_SECRET', variable: 'GEMINI_API_KEY')]) {
                        echo "Analyzing coverage files, iteration ${iteration}..."
                        sh "python3 ai_generate_promt.py '${prompt}' 'build/coverage.info' '${outputPath}'"
                    }

                    // Read generated test case and append to test file
                    def testCaseCode = readFile(file: outputPath).replaceAll('```cpp', '').replaceAll('```', '').trim()
                    writeFile(file: "tests/ai_generated_tests.cpp", text: testCaseCode, append: true)

                    // Rebuild tests for next iteration
                    sh 'make test'

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