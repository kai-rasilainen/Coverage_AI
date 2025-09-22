// This is a Declarative Pipeline script that defines your build workflow.
// It should be saved in the root of your project's repository as 'Jenkinsfile'.

pipeline {
    // 'agent any' means Jenkins can run this pipeline on any available build agent.
    agent any

    environment {
        // Add the Homebrew directory to the PATH so that Jenkins can find
        // tools like 'lcov' and 'genhtml'.
        PATH = "/opt/homebrew/bin:${env.PATH}"
    }

    // The 'stages' block contains the logical divisions of your build process.
    stages {
        stage('Build and Test') {
            steps {
                echo 'Checking out the project from the repository...'
                sh 'make all'
                sh 'build/test_number_to_string'
            }
        }
        
        stage('Generate Coverage Report') {
            steps {
                echo 'Generating code coverage report...'
                // The coverage script now includes explicit flags to handle the errors
                sh './coverage.sh'
            }
        }
    }
    
    // The 'post' block contains steps that always run after all stages have completed.
    post {
        always {
            echo 'Cleaning up the build directory...'
            sh 'make clean'
        }
    }
}