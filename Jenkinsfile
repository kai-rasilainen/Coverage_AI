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

    options {
        timestamps()
        skipDefaultCheckout(false)
    }

    // Define parameters directly in the pipeline
    parameters {
        choice(
            name: 'LOG_LEVEL',
            choices: ['INFO', 'DEBUG', 'WARNING', 'ERROR'],
            description: 'Select log level'
        )
        booleanParam(
            name: 'CLEAN_BUILD',
            defaultValue: false,
            description: 'Perform a clean build'
        )
        // Add other parameters as needed
    }

    environment {
        REQUIREMENTS_FILE = 'test_requirements.md'     // AI-generated textual test requirements
        PROMPT_SCRIPT     = 'ai_generate_promt.py'     // Python LLM driver
        COVERAGE_SCRIPT   = './coverage.sh'
        COVERAGE_INFO_FILE = 'build/coverage.info'
        PY_REQS           = 'requirements.txt'         // Python deps for the venv
        OLLAMA_MODEL      = 'llama3:8b'
        OLLAMA_HOST       = 'http://192.168.1.107:11434'
    }

    stages {
        stage('Cleanup Workspace') {
            steps {
                sh 'rm -rf venv || true'
            }
        }

        stage('Checkout and Verify') {
            steps {
                sh 'pwd && ls -la'
                // Verify key files exist, fail fast with a clear message
                script {
                    ['Makefile','coverage.sh','ai_generate_promt.py',
                     'build_context.groovy','generate_reqs.groovy',
                     'ai_coverage_loop.groovy','lcovParser.groovy','sha1Utils.groovy',
                     'src/number_to_string.h','src/number_to_string.cpp',
                     'tests/test_number_to_string.cpp'
                    ].each { f ->
                        if (!fileExists(f)) { error "Missing required file: ${f}" }
                    }
                }
                sh 'chmod +x coverage.sh || true'
            }
        }

        stage('Setup Python venv') {
            steps {
                // Use bash so we can source; or use POSIX '.' if you prefer /bin/sh
                sh '''#!/bin/bash
                    set -e
                    rm -rf venv
                    python3 -m venv venv
                    source venv/bin/activate
                    python3 -m pip install --upgrade pip
                    if [ -f requirements.txt ]; then
                      python3 -m pip install -r requirements.txt
                    fi
                '''
            }
        }

        stage('Generate Test Requirements (AI)') {
            steps {
                script {
                    // Build context and generate textual requirements with two short-lived loads
                    def ctx = load 'build_context.groovy'
                    def ctxResult = ctx.run(this) // returns [files, context]
                    def reqsGen = load 'generate_reqs.groovy'
                    reqsGen.run(this, env, params, ctxResult.context)
                    // Do not keep references to loaded scripts; they go out of scope here
                }
            }
        }

        stage('Build tests (first pass)') {
            steps {
                sh '''
                    set -e
                    mkdir -p build
                    make build/test_number_to_string
                '''
            }
        }

        stage('Iterative Coverage Improvement') {
            steps {
                script {
                    // Load helpers and run the loop in this single step only
                    def sha1Utils = load 'sha1Utils.groovy'
                    def lcovParserScript = load 'lcovParser.groovy'
                    def LcovParserClass = lcovParserScript.LcovParser
                    def loop = load 'ai_coverage_loop.groovy'
                    // Provide just the source files as context for RAG, if the loop uses it
                    def contextFiles = ['src/number_to_string.h','src/number_to_string.cpp','tests/test_number_to_string.cpp']
                    loop.run(this, env, params, sha1Utils, LcovParserClass, contextFiles)
                    // Loaded objects go out of scope when this script step ends
                }
            }
        }
    }

    post {
        always {
            echo 'Archiving artifacts...'
            // No script {} here to avoid CPS serialization of non-serializable objects
            archiveArtifacts artifacts: 'test_requirements.md', allowEmptyArchive: true
            archiveArtifacts artifacts: 'tests/ai_generated_tests.cpp', allowEmptyArchive: true
            archiveArtifacts artifacts: 'build/coverage.info', allowEmptyArchive: true
            archiveArtifacts artifacts: 'coverage_report/**', allowEmptyArchive: true

            // Best-effort cleanup
            sh 'make clean || true'
        }
        success { echo 'Pipeline completed successfully.' }
        failure { echo 'Pipeline failed. Check logs above.' }
    }
}