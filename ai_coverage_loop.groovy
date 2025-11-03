def run(script, env, params, sha1, lcovParser, CONTEXT_FILES) {
    
    // --- VARIABLE INITIALIZATION ---
    def maxIterations = 3 
    def iteration = 0
    def coverage = 0.0
    def existingTestHashes = [] 
    
    // Define files used inside the loop
    def testFile = "tests/ai_generated_tests.cpp"
    
    // Read Requirements content once, as it's needed in the prompt assembly
    def reqSpecContent = script.readFile(file: env.REQUIREMENTS_FILE, encoding: 'UTF-8')

    // Load existing test hashes once before the loop
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
        def testFileSave = "tests/ai_generated_tests_iter_${iteration}.txt"
        
        // --- CLEAR & SETUP ---
        script.echo "Preparing ai_generated_tests.cpp for iteration ${iteration}"
        script.writeFile file: testFile, text: '#include "number_to_string.h"\n#include "gtest/gtest.h"\n\n'
        script.writeFile file: testFileSave, text: '#include "number_to_string.h"\n#include "gtest/gtest.h"\n\n'

        // Run coverage script
        script.sh env.COVERAGE_SCRIPT 

        // --- LCOV PARSING AND MISS LIST GENERATION (I.1) ---
        def parseResult = lcovParser(script, env.COVERAGE_INFO_FILE)

        // Extract variables
        def linesFound = parseResult.linesFound
        def linesHit = parseResult.linesHit
        def missList = parseResult.missList 
        def functionMissMap = parseResult.functionMissMap
        
        // --- COVERAGE CHECK (Early Exit) ---
        if (linesFound > 0) {
            coverage = (linesHit / linesFound) * 100.0
        }
        script.echo "Current coverage: ${String.format('%.2f', coverage)}%"

        if (coverage >= params.min_coverage_target.toFloat()) {
            script.echo "Coverage is ${String.format('%.2f', coverage)}% which meets the target of ${params.min_coverage_target}%. Stopping iteration."
            break
        }

        // --- TARGET SELECTION AND RAG RETRIEVAL (I.1/I.3/2.A) ---
        def targetFunction = null
        functionMissMap.each { name, data ->
            if (data.hits == 0) {
                targetFunction = data
                return // Break out of the each loop
            }
        }

        def targetName = "uncovered lines listed below"
        
        // RAG Retrieval Query (I.3/2.A)
        def retrievalQuery = "Uncovered lines requiring a new test case:\n${missList.join('\n')}"
        def retrievedContextFile = "build/rag_context_iter_${iteration}.txt"
        
        // **MODIFICATION 2/3: Removed withCredentials**
        script.sh """
        BUILD_ID=dontKillMe ./venv/bin/python3 rag_context_finder.py retrieve \\
            --query "${retrievalQuery}" \\
            --output "${retrievedContextFile}"
        """
        
        def retrievedSourceContent = script.readFile(file: retrievedContextFile, encoding: 'UTF-8')
        def relevantSourceContent = retrievedSourceContent 

        // Fallback to simpler target name/content if RAG fails or target is null
        if (targetFunction) {
            targetName = "${targetFunction.name} in ${targetFunction.file}"
            script.echo "AI Target: Focusing on completely missed function: ${targetName}"
        } else {
            script.echo "No completely missed functions found. Using RAG context."
        }
        
        def missListContent = missList.join('\n')

        // --- PROMPT COMPRESSION CHECK (3.A/3.B) ---
        def RAW_CONTEXT = relevantSourceContent 
        def MAX_CHAR_THRESHOLD = 2000 
        def FINAL_CONTEXT = RAW_CONTEXT

        script.echo "Raw context size: ${RAW_CONTEXT.length()} characters."

        if (RAW_CONTEXT.length() > MAX_CHAR_THRESHOLD) {
            script.echo "Context too large (${RAW_CONTEXT.length()} chars). Summarizing..."
            def rawContextTempFile = "build/raw_context_iter_${iteration}.txt"
            def rawContextTempFileSave = "raw_context_iter_${iteration}.txt"
            script.writeFile file: rawContextTempFile, text: RAW_CONTEXT, encoding: 'UTF-8'
            script.writeFile file: rawContextTempFileSave, text: RAW_CONTEXT, encoding: 'UTF-8' 
            
            def summarizedContextFile = "build/summarized_context_iter_${iteration}.txt"
            def summarizedContextFileSave = "summarized_context_iter_${iteration}.txt"

            // **MODIFICATION 3/3: Removed withCredentials**
            script.sh """
            BUILD_ID=dontKillMe ./venv/bin/python3 summarize_code.py '${rawContextTempFile}' '${summarizedContextFile}'
            """ 
            
            FINAL_CONTEXT = script.readFile(file: summarizedContextFile, encoding: 'UTF-8')
            script.writeFile file: summarizedContextFileSave, text: FINAL_CONTEXT, encoding: 'UTF-8'
            script.echo "Summary size: ${FINAL_CONTEXT.length()} characters."
        }

        // --- ASSEMBLE FINAL PROMPT ---
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

// Add test case validation before appending
def validateAndFixTestCase(String testCode) {
    // Remove any markdown code block markers
    testCode = testCode.replaceAll('```cpp|```', '')
    
    // Ensure headers are present
    if (!testCode.contains('#include "number_to_string.h"')) {
        testCode = '#include "number_to_string.h"\n#include "gtest/gtest.h"\n\n' + testCode
    }
    
    // Fix common syntax issues
    testCode = testCode.replaceAll(/TEST\s*\(\s*(\w+)\s*,\s*(\w+)\s*\)\s*\{([^}]*)\}\s*TEST/, 'TEST($1, $2) {\n$3}\n\nTEST')
    
    // Ensure proper spacing and bracing
    testCode = testCode.replaceAll(/\}\s*\n*\s*TEST/, '}\n\nTEST')
    
    return testCode
}

// After generating test case from LLM
def generatedTestCode = script.readFile(file: outputPath).trim()
generatedTestCode = validateAndFixTestCase(generatedTestCode)

// Verify it doesn't already exist (using SHA1)
def testHash = sha1.hash(generatedTestCode)
if (!existingTestHashes.contains(testHash)) {
    script.writeFile file: testFile, text: generatedTestCode, append: true
    existingTestHashes.add(testHash)
} else {
    script.echo "Skipping duplicate test case"
}

// --- TEST GENERATION AND DEBOUNCING (I.2) ---
        def rawOutput = script.readFile(file: outputPath, encoding: 'UTF-8')

        def testCaseCode = rawOutput
            .replaceAll(/(?s)As an AI, I don't have direct access to your local file system.*?\./, '') 
            .replaceAll(/```\s*\w*\s*/, '')
            .replaceAll('```', '')
            .trim()

        if (testCaseCode.isEmpty()) {
            script.error "AI refused the prompt or generated no code. Check the model output."
        }

        def newTestHash = sha1(testCaseCode) 
        
        if (existingTestHashes.contains(newTestHash)) {
            script.echo "Warning: Generated test case is identical (hash: ${newTestHash}). Skipping rebuild and next iteration."
            iteration++
            continue
        }
        
        existingTestHashes.add(newTestHash)
        script.echo "New unique test case generated (hash: ${newTestHash}). Appending and rebuilding."

        def existingContent = script.readFile(file: testFile, encoding: 'UTF-8')
        def existingContentSave = script.readFile(file: testFileSave, encoding: 'UTF-8')
        
        def newContent = existingContent + "\n" + testCaseCode
        def newContentSave = existingContentSave + "\n" + testCaseCode
        
        script.writeFile(file: testFile, text: newContent)
        script.writeFile(file: testFileSave, text: newContentSave)

        script.echo "Rebuilding test executable..."
        script.sh 'make build/test_number_to_string'

        iteration++
    }
}

return this
