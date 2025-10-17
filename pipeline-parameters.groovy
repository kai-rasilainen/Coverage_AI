// pipeline-parameters.groovy
// This function defines and returns the array of parameter objects.
def getParams() {
    return [
        string(
            name: 'prompt_console',
            defaultValue: """Read Jenkins console output file and provide a detailed analysis of its content. Write your analysis in a clear and structured manner.""",
            description: 'The console prompt to pass to the script.'
        ),
        string(
            name: 'prompt_requirements',
            defaultValue: """Create a simple requirements.md file from source code provided below. Focus only for the unit tests.""",
            description: 'The console prompt to pass to the script.'
        ),
        string(
            name: 'prompt_coverage',
            defaultValue: """Based only on the context provided, generate the C++ source code for a Google Test case.
The test code must use the format EXPECT_EQ(expected, actual).
You must use the header file: #include "number_to_string.h".
DO NOT include any supporting class or struct definitions (like NumberGroup).
DO NOT include any headers (like iostream or gtest).
DO NOT include explanations, comments, or markdown wrappers.
Only output the raw C++ code for the test function.""",
            description: 'The coverage prompt to pass to the script.'
        ),
        string(
            name: 'min_coverage_target',
            defaultValue: '100.0',
            description: 'The minimum code coverage percentage required to stop iteration.'
        )
    ]
}

// Return the function object so it can be called from the main Jenkinsfile
return this
