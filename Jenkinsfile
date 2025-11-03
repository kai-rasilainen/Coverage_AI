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
        REQUIREMENTS_FILE = './test_requirements.md'  // Changed from requirements.md
        PROMPT_SCRIPT = 'ai_generate_promt.py'
        COVERAGE_SCRIPT = './coverage.sh'
        COVERAGE_INFO_FILE = 'build/coverage.info'
        COVERAGE_REPORT_HTML = 'coverage_report/index.html'
        OLLAMA_MODEL = 'llama3:8b'
        OLLAMA_HOST = 'http://192.168.1.107:11434'
    }

    stages {
        stage('Checkout and Verify') {
            steps {
                script {
                    echo "Current workspace: ${env.WORKSPACE}"
                    sh 'ls -la'
                    sh 'pwd'
                    
                    // Verify required files exist
                    def requiredFiles = [
                        'build_context.groovy',
                        'generate_reqs.groovy',
                        'ai_coverage_loop.groovy',
                        'sha1Utils.groovy',
                        'lcovParser.groovy',
                        'ai_generate_promt.py',
                        'coverage.sh',
                        'Makefile'
                    ]
                    
                    requiredFiles.each { file ->
                        if (!fileExists(file)) {
                            error "Required file not found: ${file}"
                        } else {
                            echo "✓ Found: ${file}"
                        }
                    }
                }
            }
        }
        
        stage('Setup Environment') {
            steps {
                script {
                    echo "Setting up Python virtual environment..."
                    sh '''#!/bin/bash
                        rm -rf venv
                        python3 -m venv venv
                        source venv/bin/activate
                        python3 -m pip install --upgrade pip
                        python3 -m pip install -r requirements.txt
                    '''
                    
                    echo "Making scripts executable..."
                    sh 'chmod +x coverage.sh'
                }
            }
        }
        
        stage('Iterative Coverage Improvement') {
            steps {
                script {
                    // Load external Groovy scripts with error handling
                    echo "Loading Groovy scripts..."
                    
                    def contextBuilder = load 'build_context.groovy'
                    echo "✓ Loaded build_context.groovy"
                    
                    def reqsGenerator = load 'generate_reqs.groovy'
                    echo "✓ Loaded generate_reqs.groovy"
                    
                    def loopRunner = load 'ai_coverage_loop.groovy'
                    echo "✓ Loaded ai_coverage_loop.groovy"
                    
                    def sha1Utils = load 'sha1Utils.groovy'
                    echo "✓ Loaded sha1Utils.groovy"
                    
                    def lcovParserScript = load 'lcovParser.groovy'
                    echo "✓ Loaded lcovParser.groovy"
                    
                    // Get the LcovParser class from the loaded script
                    def LcovParser = lcovParserScript.LcovParser
                    
                    // Runs external script, returns files and combined code context
                    echo "Building context..."
                    def contextResult = contextBuilder.run(this)
                    def CONTEXT_FILES = contextResult.files
                    def combinedContext = contextResult.context
                    
                    if (CONTEXT_FILES.isEmpty()) {
                        error "No context files found. Cannot proceed."
                    }
                    
                    echo "Context files: ${CONTEXT_FILES.join(', ')}"

                    // --- 2. REQUIREMENTS FILE GENERATION (Externalized) ---
                    echo "Generating requirements..."
                    reqsGenerator.run(this, env, params, combinedContext)
                    
                    // --- INITIAL BUILD AND HASH SETUP ---
                    echo "Building test executable for the first time..."
                    sh 'mkdir -p build' 
                    sh 'make build/test_number_to_string'
                    
                    // --- 3. AI COVERAGE LOOP EXECUTION (Externalized) ---
                    echo "Starting coverage improvement loop..."
                    loopRunner.run(this, env, params, sha1Utils, LcovParser, CONTEXT_FILES)
                }
            }
        }
    }

    post {
        always {
            echo "This will always run, regardless of the build status."
            
            // Archive artifacts without using script block
            archiveArtifacts artifacts: 'test_requirements.md', allowEmptyArchive: true
            archiveArtifacts artifacts: 'tests/ai_generated_tests.cpp', allowEmptyArchive: true
            archiveArtifacts artifacts: 'build/coverage.info', allowEmptyArchive: true
            archiveArtifacts artifacts: 'coverage_report/**', allowEmptyArchive: true
            
            // Cleanup
            sh 'make clean || true'
        }
        
        success {
            echo "Pipeline completed successfully!"
        }
        
        failure {
            echo "Pipeline failed. Check logs for details."
        }
    }
}