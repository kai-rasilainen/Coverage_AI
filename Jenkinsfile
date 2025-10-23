// 1. TOP-LEVEL SCRIPT BLOCK: Handles environment setup and parameter loading
// This block must run first to configure the job before the 'pipeline' block executes.
script {
    node('master') { 
        
        // --- CRITICAL FIX: CLEANUP VENV BEFORE ANY GIT OPERATION ---
        // These steps ensure the workspace is clean before checkout, resolving Permission Denied errors.
        // NOTE: If 'sudo' still fails, the Jenkins user must manually be granted ownership of the workspace.
        sh 'sudo chown -R jenkins:jenkins /var/lib/jenkins/workspace/Coverage_AI || true' 
        sh 'rm -rf venv || true' 
        
        // Check out the source code (SCM)
        checkout scm 

        // Load the Groovy file for parameters
        def paramsLoader = load 'pipeline-parameters.groovy'

        // Call the function to get the array of parameters.
        def externalParams = paramsLoader.getParams()

        // Use the 'properties' step to apply the parameters list to the job configuration.
        properties([
            parameters(externalParams)
        ])
    }
}
// END OF TOP-LEVEL SCRIPT BLOCK

// -----------------------------------------------------------------------------------

pipeline {
    agent any

    // Environment variables centralize configuration paths
    environment {
        REQUIREMENTS_FILE = './requirements.md'
        PROMPT_SCRIPT = 'ai_generate_promt.py'
        COVERAGE_SCRIPT = './coverage.sh'
        COVERAGE_INFO_FILE = 'build/coverage.info'
        COVERAGE_REPORT_HTML = 'coverage_report/index.html'
    }

    stages {
        stage('Iterative Coverage Improvement') {
            steps {
                script {
                    // --- SETUP AND UTILITY LOADING ---
                    def sha1 = load 'sha1Utils.groovy'
                    def lcovParser = load 'lcovParser.groovy'
                    
                    sh 'chmod +x setup_env.sh'
                    // --- VENV SETUP AND DEPENDENCY INSTALLATION ---
                    sh './setup_env.sh' 
                    
                    // --- DYNAMIC FILE DISCOVERY AND CONTEXT AGGREGATION ---
                    echo "Discovering context files and aggregating source code..."

                    def CONTEXT_FILES_LIST = findFiles(glob: 'src/**')
                    def CONTEXT_FILES = CONTEXT_FILES_LIST.findAll { 
                        !it.name.equals('main.cpp') && it.path.endsWith('.cpp')
                    }.collect { it.path }
                    
                    if (CONTEXT_FILES.isEmpty()) {
                        error "Error: No .cpp files found in the 'src' directory."
                    }

                    def combinedContext = ""
                    CONTEXT_FILES.each { filePath ->
                        try {
                            def fileContent = readFile(file: filePath, encoding: 'UTF-8')
                            combinedContext += "## File: ${filePath}\n\n${fileContent}\n\n\n"
                        } catch (FileNotFoundException e) {
                            echo "Warning: Context file not found: ${filePath}"
                        }
                    }
                    echo "Context files found: ${CONTEXT_FILES}"

                    // --- REQUIREMENTS FILE GENERATION ---
                    if (!fileExists(env.REQUIREMENTS_FILE)) { 
                        writeFile file: env.REQUIREMENTS_FILE, text: ''
                    }
                    
                    def promptForRequirements = params.prompt_requirements + combinedContext
                    def requirementsPromptFile = "build/prompt_requirements_temp.txt"
                    writeFile file: requirementsPromptFile, text: promptForRequirements, encoding: 'UTF-8' 
                    
                    withCredentials([string(credentialsId: 'GEMINI_API_KEY_SECRET', variable: 'GEMINI_API_KEY')]) {
                        echo "Writing requirements file..."
                        sh """
                        ./venv/bin/python3 ${env.PROMPT_SCRIPT} --prompt-file '${requirementsPromptFile}' '.' '${env.REQUIREMENTS_FILE}'
                        """
                    }
                    
                    // --- INITIAL BUILD AND HASH SETUP ---
                    echo "Building test executable for the first time..."
                    sh 'mkdir -p build' 
                    sh 'make build/test_number_to_string'
                    
                    // --- AI COVERAGE LOOP EXECUTION ---
                    // The core logic is now in the external Groovy file
                    def loopRunner = load 'ai_coverage_loop.groovy'
                    loopRunner.run(this, env, params, sha1, lcovParser, CONTEXT_FILES)
                }
            }
        }
    }

    post {
        always {
            echo "This will always run, regardless of the build status."
            
            // --- ARTIFACT ARCHIVAL (II.2) ---
            archiveArtifacts artifacts: """
                ${env.REQUIREMENTS_FILE},
                tests/ai_generated_tests.cpp,
                ${env.COVERAGE_INFO_FILE}
            """
            archiveArtifacts artifacts: 'coverage_report/**', allowEmptyArchive: true
            
            // --- CLEANUP ---
            script {
                sh 'make clean' 
            }
        }
    }
}