// This is a Declarative Pipeline script that defines your build workflow.
// It should be saved in the root of your project's repository as 'Jenkinsfile'.

pipeline {
    // 'agent any' means Jenkins can run this pipeline on any available build agent.
    agent any

    environment {
        // Add the Homebrew bin directory to the PATH so that Jenkins can find
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
                    def jenkinsHome = "/Users/rasilainen/.jenkins"
                    def jobName = "${env.JOB_NAME}"
                    def buildNumber = "${env.BUILD_NUMBER}"
                    def logPath = "${jenkinsHome}/jobs/${jobName}/builds/${buildNumber}/log"
                    def outputPath = "${jobName}_build_${buildNumber}_analysis.txt"
                    
                    // Use a withCredentials block to securely provide the API key
                    withCredentials([string(credentialsId: 'GEMINI_API_KEY_SECRET', variable: 'GEMINI_API_KEY')]) {
                        echo "Analyzing Jenkins console log file..."
                        // Correctly run the Python script with python3 and pass the log path and output path as arguments
                        sh "python3 ai_generate_promt.py '${logPath}' '${outputPath}'"
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
