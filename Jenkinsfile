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
    }

    environment {
        REQUIREMENTS_FILE = 'test_requirements.md'
        PROMPT_SCRIPT     = 'ai_generate_promt.py'
        COVERAGE_SCRIPT   = './coverage.sh'
        COVERAGE_INFO_FILE = 'build/coverage.info'
        PY_REQS           = 'requirements.txt'
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
                    def ctx = load 'build_context.groovy'
                    def ctxResult = ctx.run(this)
                    def reqsGen = load 'generate_reqs.groovy'
                    reqsGen.run(this, env, params, ctxResult.context)
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
                    def sha1Utils = load 'sha1Utils.groovy'
                    def lcovParserScript = load 'lcovParser.groovy'
                    def LcovParserClass = lcovParserScript.LcovParser
                    def loop = load 'ai_coverage_loop.groovy'
                    def contextFiles = ['src/number_to_string.h','src/number_to_string.cpp','tests/test_number_to_string.cpp']
                    loop.run(this, env, params, sha1Utils, LcovParserClass, contextFiles)
                }
            }
        }
    }

    post {
        always {
            echo 'Archiving artifacts...'
            archiveArtifacts artifacts: 'test_requirements.md', allowEmptyArchive: true
            archiveArtifacts artifacts: 'tests/ai_generated_tests.cpp', allowEmptyArchive: true
            archiveArtifacts artifacts: 'build/coverage.info', allowEmptyArchive: true
            archiveArtifacts artifacts: 'coverage_report/**', allowEmptyArchive: true
            sh 'make clean || true'
        }
        success { echo 'Pipeline completed successfully.' }
        failure { echo 'Pipeline failed. Check logs above.' }
    }
}