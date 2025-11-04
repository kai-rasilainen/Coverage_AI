def run(script, env, params, sha1Utils, LcovParserClass, CONTEXT_FILES) {
    def maxIterations = 3
    def iteration = 0
    def testFile = 'tests/ai_generated_tests.cpp'
    def promptFile = 'build/prompt.txt'
    def outputFile = 'build/ai_generated_test.txt'
    def coveragePct = 0.0

    // Ensure test file has headers once
    if (!script.fileExists(testFile)) {
        script.writeFile(file: testFile, text: '#include "number_to_string.h"\n#include "gtest/gtest.h"\n\n')
    }

    // Parser instance is local to this step
    def lcovParser = LcovParserClass.newInstance()

    while (iteration < maxIterations) {
        script.echo "=== Iteration ${iteration + 1}/${maxIterations} ==="

        // Run tests and collect coverage
        script.sh "${env.COVERAGE_SCRIPT}"

        // Parse coverage
        def cov = lcovParser.parseCoverage(script, env.COVERAGE_INFO_FILE)
        if ((cov.linesFound ?: 0) == 0) {
            script.echo "No coverage data found (build/coverage.info missing or empty)."
            break
        }
        coveragePct = (cov.linesHit as double) / (cov.linesFound as double) * 100.0
        script.echo String.format("Current coverage: %.2f%%", coveragePct)
        if (coveragePct >= 100.0) {
            script.echo "Coverage is 100%. Done."
            break
        }

        // Build prompt from miss list
        def missList = (cov.missList ?: []).join('\n')
        def prompt = """Create additional GoogleTest cases to cover these uncovered lines:

${missList}

Rules:
- Each test is a separate TEST(TestSuite, TestName)
- No nested TESTs, proper braces
- Use functions from number_to_string.h
- Output ONLY C++ test code, no explanations.
"""

        script.writeFile(file: promptFile, text: prompt)
        script.sh """
            set -e
            ./venv/bin/python3 ${env.PROMPT_SCRIPT} \
                --prompt-file "${promptFile}" \
                --output-file "${outputFile}" \
                --requirements-file "${env.REQUIREMENTS_FILE}"
        """
        if (!script.fileExists(outputFile)) {
            script.error "AI output not found: ${outputFile}"
        }

        def raw = script.readFile(file: outputFile, encoding: 'UTF-8').trim()
        def fixed = validateAndFixTestCase(raw)
        if (fixed) {
            def hash = sha1Utils.hash(fixed)
            // avoid simple duplicates by hash-of-block
            def existing = script.readFile(file: testFile, encoding: 'UTF-8')
            if (!existing.contains(hash)) {
                script.writeFile(file: testFile, text: "\n// HASH:${hash}\n${fixed}\n", append: true)
            } else {
                script.echo "Duplicate test skipped."
            }
        }

        // Rebuild tests for next iteration
        script.sh 'make build/test_number_to_string'
        iteration++
    }

    script.echo String.format("Final coverage: %.2f%%", coveragePct)
}

// Keep this NonCPS to avoid CPS serialization issues for regex processing
@NonCPS
def validateAndFixTestCase(String code) {
    if (code == null) return ""
    def cleaned = code.replaceAll('```cpp|```', '').trim()

    // Ensure tests are not nested: split by TEST( and rejoin with braces fixed
    // Also ensure each TEST block ends with a closing brace.
    // Lightweight normalizer:
    cleaned = cleaned.replaceAll(/(?m)\}\s*TEST\(/, "}\n\nTEST(")
    // If file lacks headers, we do not re-add here (main test file has them)

    // Drop accidental includes from model duplicates except gtest/number_to_string
    def lines = cleaned.readLines()
    def kept = []
    lines.each { ln ->
        if (ln.trim().startsWith('#include') && !ln.contains('gtest') && !ln.contains('number_to_string.h')) {
            // skip
        } else {
            kept << ln
        }
    }
    return kept.join('\n').trim()
}

return this
