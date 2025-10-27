def run(script, env, params, combinedContext) {
    // Note: All Jenkins steps (echo, writeFile, sh, fileExists) must be prefixed with 'script.'

    // 1. Check if the requirements file exists, and create it if not (empty content).
    if (!script.fileExists(env.REQUIREMENTS_FILE)) { 
        script.writeFile file: env.REQUIREMENTS_FILE, text: ''
    }
    
    // 2. Assemble the full prompt content.
    def promptForRequirements = params.prompt_requirements + combinedContext
    def requirementsPromptFile = "build/prompt_requirements_temp.txt"
    
    // 3. Write the prompt content to a temporary file.
    script.writeFile file: requirementsPromptFile, text: promptForRequirements, encoding: 'UTF-8' 
    
    // 4. Execute the Python script. No 'withCredentials' wrapper is needed for local Ollama.
    script.echo "Writing requirements file using Ollama..."
    script.sh """
    ./venv/bin/python3 ${env.PROMPT_SCRIPT} --prompt-file '${requirementsPromptFile}' '.' '${env.REQUIREMENTS_FILE}'
    """
}

return this // Returns the object containing the 'run' method

