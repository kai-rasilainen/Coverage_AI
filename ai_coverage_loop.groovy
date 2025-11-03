def run(script, env, params, sha1, lcovParser, CONTEXT_FILES) {
    // --- VARIABLE INITIALIZATION ---
    def maxIterations = 3 
    def iteration = 0
    def coverage = 0.0
    def existingTestHashes = [] 
    
    // Define files used inside the loop
    def promptFile = "build/prompt.txt"
    def outputFile = "build/ai_generated_test.txt"
    
    // Define validation closure
    def validateAndFixTestCase = { String testCode ->
        testCode = testCode.replaceAll('```cpp|```', '')
        if (!testCode.contains('#include "number_to_string.h"')) {
            testCode = '#include "number_to_string.h"\n#include "gtest/gtest.h"\n\n' + testCode
        }
        testCode = testCode.replaceAll(/TEST\s*\(\s*(\w+)\s*,\s*(\w+)\s*\)\s*\{([^}]*)\}\s*TEST/, 'TEST($1, $2) {\n$3}\n\nTEST')
        testCode = testCode.replaceAll(/\}\s*\n*\s*TEST/, '}\n\nTEST')
        return testCode
    }

    // Read Requirements content once, as it's needed in the prompt assembly
    def reqSpecContent = script.readFile(file: env.REQUIREMENTS_FILE, encoding: 'UTF-8')

    // Load existing test hashes once before the loop
    def testFile = "tests/ai_generated_tests.cpp"
    if (script.fileExists(testFile)) {
        script.echo "Initializing hash list from existing tests..."
        def existingContent = script.readFile(file: testFile, encoding: 'UTF-8')
        def testBlocks = existingContent.split(/(?=\nTEST\()/) 
        testBlocks.each { block ->
            if (block.trim().startsWith('TEST(')) {
                existingTestHashes.add(sha1(block.trim()))
            }
        }
    }
    
    // -------------------------------------------------------------------
    // --- RAG INDEXING (Ollama/Local Ready - NO CREDENTIALS) ---
    script.echo "Indexing codebase for Semantic Search (RAG) for Ollama..."
    def contextFilesString = CONTEXT_FILES.join(' ')
    
    // **MODIFICATION 1/3: Removed withCredentials**
    script.sh """
    BUILD_ID=dontKillMe ./venv/bin/python3 rag_context_finder.py index --files ${contextFilesString}
    """
    // -------------------------------------------------------------------
    
    
    // --- ITERATION LOOP START ---
    while (iteration < maxIterations) {
        script.echo "=== ITERATION ${iteration + 1} / ${maxIterations} ==="
        
        // --- RUN COVERAGE SCRIPT ---
        script.sh "${env.COVERAGE_SCRIPT}"
        
        // --- PARSE COVERAGE ---
        def coverageData = lcovParser.parseCoverage(script, env.COVERAGE_INFO_FILE)
        coverage = coverageData.percentage
        script.echo "Current coverage: ${coverage}%"
        
        if (coverage >= 100.0) {
            script.echo "✓ Coverage is 100%. Stopping iteration."
            break
        }
        
        // --- GET UNCOVERED LINES ---
        def missListContent = lcovParser.getUncoveredLines(script, env.COVERAGE_INFO_FILE)
        
        // --- RAG CONTEXT RETRIEVAL ---
        def FINAL_CONTEXT = script.sh(
            script: """
            ./venv/bin/python3 rag_context_finder.py query --query "${missListContent}"
            """,
            returnStdout: true
        ).trim()

        // --- ASSEMBLE PROMPT ---
        def prompt = """
Your task is to write Google Test cases to improve code coverage. 
Follow these strict formatting rules:

1. Each test must be a separate TEST macro (no nesting)
2. Each test must have proper opening and closing braces
3. Include required headers at the top:
   #include "number_to_string.h"
   #include "gtest/gtest.h"

Required Test Format:
TEST(TestSuiteName, TestName) {
    // test assertions here
}

Current Coverage Gaps:
${missListContent}

Context:
${FINAL_CONTEXT}

Requirements:
${reqSpecContent}

Generate only the test code, no explanations.
"""

        // --- ASSEMBLE AND EXECUTE PROMPT ---
        script.writeFile(file: promptFile, text: prompt)
        script.sh """
            mkdir -p build
            ./venv/bin/python3 ${env.PROMPT_SCRIPT} \
                --prompt-file "${promptFile}" \
                --output-file "${outputFile}" \
                --requirements-file "${env.REQUIREMENTS_FILE}"
        """

        // --- TEST GENERATION AND VALIDATION ---
        if (!script.fileExists(outputFile)) {
            script.error "AI output file not found at ${outputFile}"
        }

        def rawOutput = script.readFile(file: outputFile, encoding: 'UTF-8')
        def testCaseCode = validateAndFixTestCase(rawOutput)

        if (testCaseCode.isEmpty()) {
            script.error "AI refused the prompt or generated no code. Check the model output."
        }

        def newTestHash = sha1(testCaseCode)
        
        if (!existingTestHashes.contains(newTestHash)) {
            script.writeFile file: testFile, text: "\n${testCaseCode}\n", append: true
            existingTestHashes.add(newTestHash)
            script.echo "✓ New test case added."
        } else {
            script.echo "⚠ Duplicate test detected, skipping."
        }
        
        // --- REBUILD AND RE-RUN TESTS ---
        script.sh 'make clean'
        script.sh 'make build/test_number_to_string'
        
        iteration++
    }
    
    script.echo "=== Coverage Loop Complete ==="
    script.echo "Final coverage: ${coverage}%"
}

return this
