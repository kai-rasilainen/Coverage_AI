// 1. TOP-LEVEL SCRIPT BLOCK: Handles environment setup and parameter loading
// This block must run first to configure the job before the 'pipeline' block executes.
script {
    node('master') { 
        
        // --- CRITICAL FIX: CLEANUP VENV BEFORE ANY GIT OPERATION ---
        // Ensures the workspace is clean before Git checkout to avoid Permission Denied errors.
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
        OLLAMA_MODEL = 'llama3:8b' // Use the 8B tag, which is the most common default version
        OLLAMA_HOST = 'http://192.168.1.107:11434'
    }

    stages {
        stage('Iterative Coverage Improvement') {
            steps {
                script {
                    // Load external Groovy scripts
                    def contextBuilder = load 'build_context.groovy'
                    def reqsGenerator = load 'generate_reqs.groovy'
                    def loopRunner = load 'ai_coverage_loop.groovy'
                    def sha1Utils = load 'sha1Utils.groovy'
                    def lcovParserScript = load 'lcovParser.groovy'
                    
                    // Get the LcovParser class from the loaded script
                    def LcovParser = lcovParserScript.LcovParser
                    
                    // Runs external script, returns files and combined code context
                    def contextResult = contextBuilder.run(this)
                    def CONTEXT_FILES = contextResult.files
                    def combinedContext = contextResult.context
                    
                    if (CONTEXT_FILES.isEmpty()) {
                        error "No context files found. Cannot proceed."
                    }

                    // --- 2. REQUIREMENTS FILE GENERATION (Externalized) ---
                    reqsGenerator.run(this, env, params, combinedContext)
                    
                    // --- INITIAL BUILD AND HASH SETUP ---
                    echo "Building test executable for the first time..."
                    sh 'mkdir -p build' 
                    sh 'make build/test_number_to_string'
                    
                    // --- 3. AI COVERAGE LOOP EXECUTION (Externalized) ---
                    loopRunner.run(this, env, params, sha1Utils, LcovParser, CONTEXT_FILES)
                }
            }
        }
    }

    post {
        always {
            echo "This will always run, regardless of the build status."
            
            // --- ARTIFACT ARCHIVAL ---
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