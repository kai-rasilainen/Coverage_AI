def run(script, env, params, combinedContext) {
    script.echo '--- 2. REQUIREMENTS FILE GENERATION ---'
    def promptFile = 'build/prompt_requirements.txt'
    def outputFile = env.REQUIREMENTS_FILE

    def prompt = """Analyze the following C++ code and generate concise, testable requirements for unit tests.

${combinedContext}

Format:
- One requirement per line
- Be specific about inputs and outputs
- Cover edge cases (negative, zero, positive)"""

    script.writeFile(file: promptFile, text: prompt)
    script.sh """
        set -e
        mkdir -p build
        ./venv/bin/python3 ${env.PROMPT_SCRIPT} \
            --prompt-file "${promptFile}" \
            --output-file "${outputFile}"
    """
    if (!script.fileExists(outputFile)) {
        script.error "Failed to generate requirements: ${outputFile} not found"
    }
    script.echo "✓ Requirements written to ${outputFile}"
}
return this

