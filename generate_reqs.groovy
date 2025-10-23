def run(script, env, params, combinedContext) {
    // --- REQUIREMENTS FILE GENERATION ---
    if (!script.fileExists(env.REQUIREMENTS_FILE)) { 
        script.writeFile file: env.REQUIREMENTS_FILE, text: ''
    }
    
    def promptForRequirements = params.prompt_requirements + combinedContext
    def requirementsPromptFile = "build/prompt_requirements_temp.txt"
    script.writeFile file: requirementsPromptFile, text: promptForRequirements, encoding: 'UTF-8' 
    
    script.withCredentials([script.string(credentialsId: 'GEMINI_API_KEY_SECRET', variable: 'GEMINI_API_KEY')]) {
        script.echo "Writing requirements file..."
        script.sh """
        ./venv/bin/python3 ${env.PROMPT_SCRIPT} --prompt-file '${requirementsPromptFile}' '.' '${env.REQUIREMENTS_FILE}'
        """
    }
}

return this
