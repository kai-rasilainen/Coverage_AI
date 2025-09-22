pipeline {
    // 'agent any' means Jenkins can run this pipeline on any available build agent.
    agent any

    // Define parameters for the pipeline
    parameters {
        string(
            name: 'prompt_console',
            defaultValue: """Read Jenkins console output file and provide a detailed analysis of its content. Write your analysis in a clear and structured manner. Focus on errors and problems, and find solution to them.""",
            description: 'The console prompt to pass to the script.')
        string(
            name: 'prompt_coverage',
            defaultValue: """Provide a C++ test case source code to improve code coverage for the coverage reports in folder reports. Use the Google Test framework and the same style as test_number_to_string.cpp. You MUST use the header file: #include "number_to_string.h", NOT "ai_created_test_case.h" """,
            description: 'The coverage prompt to pass to the script.')
    }

    // The 'stages' block contains the logical divisions of your build process.
    stages {
        stage('Iterative Coverage Improvement') {
            steps {
                script {
                    // Maximum number of iterations to prevent infinite loops
                    def maxIterations = 3
                    def iteration = 0
                    def coverage = 0.0

                    // Loop to run tests and generate new test cases
                    while (iteration < maxIterations) {
                        // Check if the AI-generated test file exists and create it if it doesn't.
                        if (!fileExists('tests/ai_generated_tests.cpp')) {
                            echo "Creating empty ai_generated_tests.cpp"
                            sh 'touch tests/ai_generated_tests.cpp'
                        }

                        // Run coverage script to build and update reports
                        sh './coverage.sh'

                        // Parse the coverage percentage from the coverage.info file
                        def coverageInfoContent = readFile(file: "reports/coverage.info")
                        def linesFound = (coverageInfoContent =~ /^LF:(\d+)/).collect { it[1] as int }.sum()
                        def linesHit = (coverageInfoContent =~ /^LH:(\d+)/).collect { it[1] as int }.sum()

                        if (linesFound > 0) {
                            coverage = (linesHit.toBigDecimal() / linesFound.toBigDecimal()) * 100
                        } else {
                            coverage = 0.0
                        }

                        echo "Current coverage: ${coverage}%"

                        if (coverage >= 100.0) {
                            echo "Coverage is 100%. Stopping iteration."
                            break
                        }

                        // Prepare the prompt for the Gemini API, including the coverage report content
                        def prompt = "${params.prompt_coverage}\n\nCoverage Report Content:\n${readFile(file: 'reports/index.html')}"

                        def outputPath = "build_${env.BUILD_NUMBER}_coverage_analysis_${iteration}.txt"

                        // Call the Python script to generate a new test case
                        withCredentials([string(credentialsId: 'GEMINI_API_KEY_SECRET', variable: 'GEMINI_API_KEY')]) {
                            echo "Analyzing coverage files, iteration ${iteration}..."
                            sh "python3 ai_generate_promt.py '${prompt}' 'dummy_log' '${outputPath}'"
                        }

                        // Read the generated test case and append it to the test file
                        def testCaseCode = readFile(file: outputPath)
                        writeFile(file: "tests/ai_generated_tests.cpp", text: testCaseCode, append: true)

                        iteration++
                    }
                }
            }
        }
    }
}
