def run(script, env, params, combinedContext) {
    script.echo "--- 2. REQUIREMENTS FILE GENERATION ---"
    
    def promptFile = "build/prompt_requirements_temp.txt"
    def outputFile = env.REQUIREMENTS_FILE
    
    def requirementsPrompt = """
Analyze the following C++ code and generate comprehensive functional requirements.
Format the requirements as clear, testable specifications.

Code to analyze:
${combinedContext}

Generate requirements covering:
1. Function behaviors
2. Edge cases
3. Error handling
4. Input validation
5. Expected outputs

Output format: Plain text requirements, one per line.
"""

    script.writeFile(file: promptFile, text: requirementsPrompt)
    
    script.sh """
        mkdir -p build
        ./venv/bin/python3 ${env.PROMPT_SCRIPT} \
            --prompt-file "${promptFile}" \
            --output-file "${outputFile}"
    """
    
    if (script.fileExists(outputFile)) {
        script.echo "✓ Requirements file generated at ${outputFile}"
    } else {
        script.error "Failed to generate requirements file"
    }
}

return this

