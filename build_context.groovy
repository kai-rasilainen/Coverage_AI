def run(script) {
    script.echo '--- 1. BUILDING CODE CONTEXT ---'
    def sourceFiles = [
        'src/number_to_string.h',
        'src/number_to_string.cpp',
        'src/main.cpp',
        'tests/test_number_to_string.cpp'
    ]
    def existing = []
    def combined = new StringBuilder()

    sourceFiles.each { f ->
        if (script.fileExists(f)) {
            def content = script.readFile(file: f, encoding: 'UTF-8')
            combined.append("""\n// ============================================
// FILE: ${f}
// ============================================
${content}
""")
            existing.add(f)
        } else {
            script.echo "⚠ Missing: ${f}"
        }
    }

    if (existing.isEmpty()) {
        script.error 'No source files found for context building!'
    }

    script.echo "Context built from ${existing.size()} files"
    return [files: existing, context: combined.toString()]
}
return this