def run(script) {
    // --- DYNAMIC FILE DISCOVERY AND CONTEXT AGGREGATION ---
    script.echo "Discovering context files and aggregating source code..."

    def CONTEXT_FILES_LIST = script.findFiles(glob: 'src/**')
    def CONTEXT_FILES = CONTEXT_FILES_LIST.findAll { 
        // Filter out main.cpp and keep only .cpp files
        !it.name.equals('main.cpp') && it.path.endsWith('.cpp')
    }.collect { it.path }
    
    if (CONTEXT_FILES.isEmpty()) {
        script.error "Error: No .cpp files found in the 'src' directory."
    }

    // Build combinedContext
    def combinedContext = ""
    CONTEXT_FILES.each { filePath ->
        try {
            def fileContent = script.readFile(file: filePath, encoding: 'UTF-8')
            combinedContext += "## File: ${filePath}\n\n${fileContent}\n\n\n"
        } catch (FileNotFoundException e) {
            script.echo "Warning: Context file not found: ${filePath}"
        }
    }
    script.echo "Context files found: ${CONTEXT_FILES}"

    // Return the two crucial variables as a Map
    return [
        files: CONTEXT_FILES,
        context: combinedContext
    ]
}

return this
