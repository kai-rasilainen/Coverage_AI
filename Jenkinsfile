// This is a Declarative Pipeline script that defines your build workflow.
// It should be saved in the root of your project's repository as 'Jenkinsfile'.

pipeline {
    // 'agent any' means Jenkins can run this pipeline on any available build agent.
    agent any
    
    // Define the parameter to be passed to the script
    parameters {
        string(
            name: 'prompt_console', 
            defaultValue: """Read Jenkins console output file and provide a detailed analysis of its content. Write your analysis in a clear and structured manner.""",
            description: 'The console prompt to pass to the script.')

        string(
            name: 'prompt_coverage', 
            defaultValue: """Provide a C++ test case source code to improve code coverage for the coverage reports in folder reports. Use the Google Test framework and the same style as test_number_to_string.cpp.""",
            description: 'The coverage prompt to pass to the script.')
    }

    environment {
        // Set the timezone for the build to ensure consistent timestamps.
        TZ = 'Europe/Helsinki'

        // Add the directory to the PATH so that Jenkins can find
        // tools like 'lcov' and 'genhtml'.
        PATH = "/var/lib:${env.PATH}"
    }
    
    // The 'stages' block contains the logical divisions of your build process.
    stages {
        stage('Checkout Code') {
            steps {
                // This step checks out the code from the repository.
                // It is automatically handled by the SCM configuration in your project.
                echo 'Checking out the project from the repository...'
            }
        }
        
        stage('Build') {
            steps {
                // This is where your core build commands would go.
                // Replace 'echo' with your actual build command (e.g., mvn, npm, etc.).
                echo 'Starting the build process...'
                sh 'make all'
                sh 'build/main 100 MY_GROUP'
                sh 'make coverage'
            }
        }
        /*
        stage('Test') {
            steps {
                // This stage is for running your tests.
                // Replace 'echo' with your actual test command.
                echo 'Running tests...'
                sh './coverage.sh'
            }
        }
        
        stage('Analyze Console Log with Gemini') {
            steps {
                script {
                    // Dynamically get the paths for the build log and output file
                    def jenkinsHome = "/var/lib/jenkins"
                    def jobName = "${env.JOB_NAME}"
                    def buildNumber = "${env.BUILD_NUMBER}"
                    def logPath = "${jenkinsHome}/jobs/${jobName}/builds/${buildNumber}/log"
                    def outputPath = "build_${buildNumber}_console_analysis.txt"
                    
                    // Use a withCredentials block to securely provide the API key
                    withCredentials([string(credentialsId: 'GEMINI_API_KEY_SECRET', variable: 'GEMINI_API_KEY')]) {
                        echo "Analyzing Jenkins console log file..."
                        // Correctly run the Python script with python3 and pass the log path and output path as arguments
                        sh "python3 ai_generate_promt.py '${params.prompt_console}' '${logPath}' '${outputPath}'"
                    }
                }
            }
        }
        stage('Analyze Coverage Report') {
            steps { 
                script {
                    // Dynamically get the paths for the build log and output file
                    def jenkinsHome = "/var/lib/jenkins"
                    def jobName = "${env.JOB_NAME}"
                    def buildNumber = "${env.BUILD_NUMBER}"
                    def logPath = "${jenkinsHome}/jobs/${jobName}/builds/${buildNumber}/log"
                    def outputPath = "build_${buildNumber}_coverage_analysis.txt"
                    def coverageReportContent = readFile(file: "reports/index.html")
                    def prompt = """
                    Analyze the following HTML code coverage report from lcov. 
                    Identify the lines of code that are not covered by tests and write a C++ test case using the Google Test framework to cover those lines.
                    The new test case should be in the same style as test_number_to_string.cpp.

                    Coverage Report Content: ${coverageReportContent}

                    Write only the C++ code for the new test case, and nothing else.
                    """

                    // Use a withCredentials block to securely provide the API key
                    withCredentials([string(credentialsId: 'GEMINI_API_KEY_SECRET', variable: 'GEMINI_API_KEY')]) {
                        echo "Analyzing coverage files..."
                        // Correctly run the Python script with python3 and pass the log path and output path as arguments
                        sh "python3 ai_generate_promt.py '${prompt}' '${logPath}' '${outputPath}'"
                    }
                }
            }
        }

        stage('Create New Test File') {
            steps {
                script {
                    echo 'Creating a new test file with the generated code...'
                    def testCaseCode = readFile(file: "build_${env.BUILD_NUMBER}_coverage_analysis.txt")
                    // Clean up the string by removing the markdown code block tags.
                    testCaseCode = testCaseCode.replaceAll('```cpp', '').replaceAll('```', '').trim()
                    writeFile(file: "tests/ai_created_test_case.cpp", text: testCaseCode)
                }
            }
        }
        */
        stage('Iterative Coverage Improvement') {
            steps {
                script {
                    def maxIterations = 10
                    def iteration = 0
                    def coverage = 0

                    while (iteration < maxIterations) {
                        // Run coverage script to update reports
                        sh './coverage.sh'

                        // Parse coverage percentage from the .info file
                        def coverageInfoContent = readFile(file: "reports/coverage.info")
                        def linesFound = 0
                        def linesHit = 0

                        def lfMatcher = coverageInfoContent =~ /LF:(\d+)/
                        if (lfMatcher) {
                            linesFound = lfMatcher[0][1] as int
                        }

                        def lhMatcher = coverageInfoContent =~ /LH:(\d+)/
                        if (lhMatcher) {
                            linesHit = lhMatcher[0][1] as int
                        }
                        
                        sh """
                          linesFound=${linesFound}
                          linesHit=${linesHit}
                          if [ \$linesFound -gt 0 ]; then
                            coverage=\$(echo "scale=2; (\$linesHit / \$linesFound) * 100" | bc)
                          else
                            coverage=0
                          fi
                          echo "Calculated coverage: \$coverage"
                          echo "coverage=\$coverage" > coverage.env
                        """
                        
                        def coverageEnv = readProperties file: 'coverage.env'
                        coverage = coverageEnv.coverage as Float

                        if (linesFound == 0) {
                            error("Could not parse coverage percentage from report.")
                        }

                        echo "Current coverage: ${coverage}%"

                        if (coverage >= 100.0) {
                            echo "Coverage is 100%. Stopping iteration."
                            break
                        }

                        // Prepare prompt for Gemini
                        def prompt = """
                        Analyze the following HTML code coverage report from lcov. 
                        Identify the lines of code that are not covered by tests and write a C++ test case using the Google Test framework to cover those lines.
                        The new test case should be in the same style as test_number_to_string.cpp.

                        Coverage Report Content: ${coverageReportContent}

                        Write only the C++ code for the new test case, and nothing else.
                        """

                        def outputPath = "build_${env.BUILD_NUMBER}_coverage_analysis_${iteration}.txt"
                        def coverageReportContent = readFile(file: "reports/index.html")

                        withCredentials([string(credentialsId: 'GEMINI_API_KEY_SECRET', variable: 'GEMINI_API_KEY')]) {
                            echo "Analyzing coverage files, iteration ${iteration}..."
                            sh "python3 ai_generate_promt.py '${prompt}' 'dummy_log' '${outputPath}'"
                        }

                        // Read generated test case and append to test file
                        def testCaseCode = readFile(file: outputPath)
                        testCaseCode = testCaseCode.replaceAll('```cpp', '').replaceAll('```', '').trim()
                        writeFile(file: "tests/ai_created_test_case.cpp", text: testCaseCode, append: true)

                        // Rebuild tests for next iteration
                        sh 'make test'

                        iteration++
                    }
                }
            }
        }
    }
    
    // The 'post' block defines actions to be performed after the main stages have finished.
    // These actions are conditional based on the build's final status.
    post {
        success {
            echo 'The build was successful! Running post-build commands.'
            // Add any commands to run only after a successful build here.
            // For example, deploying the application or running a script.
            //sh 'echo "Build succeeded, running a cleanup script."'
        }
        
        failure {
            echo 'The build failed. Notifying the team.'
            // Add any commands to run only after a failed build here.
            // For example, sending an email or a Slack notification.
        }
        
        always {
            echo 'This will always run, regardless of the build status.'
            // Commands here will execute even if the build was successful or failed.
            //sh "python3 ai_generate_promt.py /Users/rasilainen/.jenkins/jobs/Coverage_AI_pipeline/builds/${env.BUILD_NUMBER}/log output.txt"
        }
    }
}
