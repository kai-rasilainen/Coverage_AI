class LcovParser {
    /**
     * Parses an LCOV coverage info file content to calculate coverage metrics
     * and generate a list of uncovered lines (missList).
     * @param steps The 'steps' object from the Jenkins context (to access readFile, etc.)
     * @param coverageInfoFile The path to the LCOV file (e.g., 'build/coverage.info')
     * @return A map containing linesFound, linesHit, missList, and functionMissMap.
     */
    def parseCoverage(steps, coverageInfoFile) {
        def script = steps 

        // Initialize return map variables
        def coverageInfoContent = '' 
        def linesFound = 0
        def linesHit = 0
        def missList = []
        def currentFile = null
        def functionMissMap = [:] 

        try {
            coverageInfoContent = script.readFile(file: coverageInfoFile, encoding: 'UTF-8')
        } catch (FileNotFoundException e) {
            script.echo "Error: LCOV file not found at ${coverageInfoFile}"
            return [
                linesFound: 0, 
                linesHit: 0, 
                missList: [], 
                functionMissMap: [:]
            ]
        }

        def lines = coverageInfoContent.split('\n')

        for (line in lines) {
            if (line.startsWith("SF:")) { currentFile = line.substring(3) }
            else if (line.startsWith("FN:")) { // Function Name definition
                def parts = line.substring(3).split(',')
                functionMissMap[parts[1]] = [file: currentFile, startLine: parts[0], hits: 0]
            } else if (line.startsWith("FNDA:") && line.endsWith(',0')) { // Function hit data (0 hits)
                def functionName = line.substring(5).split(',')[1]
                if (functionMissMap.containsKey(functionName)) {
                    functionMissMap[functionName].hits = 0
                }
            } else if (line.startsWith("DA:") && line.endsWith(',0')) { // Data line with 0 hits
                def lineNumber = line.substring(3).split(',')[0]
                missList.add("File: ${currentFile} Line: ${lineNumber} (Uncovered)")
            }
            if (line.startsWith("LF:")) { linesFound = line.substring(3).toInteger() }
            if (line.startsWith("LH:")) { linesHit = line.substring(3).toInteger() }
        }
        
        // This is the last expression, which is returned by the method
        return [
            linesFound: linesFound, 
            linesHit: linesHit, 
            missList: missList, 
            functionMissMap: functionMissMap
        ]
    }
}