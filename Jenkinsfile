// This is a Declarative Pipeline script that defines your build workflow.
// It should be saved in the root of your project's repository as 'Jenkinsfile'.

pipeline {
    // 'agent any' means Jenkins can run this pipeline on any available build agent.
    agent any

    environment {
        // Add the directory to the PATH so that Jenkins can find
        // tools like 'lcov' and 'genhtml'.
        PATH = "/opt/homebrew/bin:${env.PATH}"
    }

    // The 'stages' block contains the logical divisions of your build process.
    stages {
        stage('Build and Test') {
            steps {
                // This step checks out the code from the repository.
                // It is automatically handled by the SCM configuration in your project.
                echo 'Checking out the project from the repository...'
                
                // Build the project
                echo 'Starting the build process...'
                sh 'make all'
                
                // Run the test binary to ensure it's executable
                sh 'build/test_number_to_string'
            }
        }
        
        stage('Generate Coverage Report') {
            steps {
                echo 'Generating code coverage report...'
                sh './coverage.sh'
            }
        }
    }
    
    // The 'post' block contains steps that always run after all stages have completed.
    post {
        always {
            echo 'Cleanup...'
            sh 'make clean'
        }
    }
}
