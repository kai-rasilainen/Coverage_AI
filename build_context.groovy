def run(script) {
    script.echo "--- 1. BUILDING CODE CONTEXT ---"
    
    // Define the source files to include in the context
    def sourceFiles = [
        'src/number_to_string.h',
        'src/number_to_string.cpp',
        'src/main.cpp',
        'tests/test_number_to_string.cpp'
    ]
    
    def existingFiles = []
    def combinedContext = ""
    
    // Read and combine all source files
    sourceFiles.each { file ->
        if (script.fileExists(file)) {
            script.echo "✓ Reading: ${file}"
            def content = script.readFile(file: file, encoding: 'UTF-8')
            combinedContext += """
// ============================================
// FILE: ${file}
// ============================================
${content}

"""
            existingFiles.add(file)
        } else {
            script.echo "⚠ File not found: ${file}"
        }
    }
    
    if (existingFiles.isEmpty()) {
        script.error "No source files found for context building!"
    }
    
    script.echo "Context built from ${existingFiles.size()} files"
    
    // Return both the file list and the combined content
    return [
        files: existingFiles,
        context: combinedContext
    ]
}

return this