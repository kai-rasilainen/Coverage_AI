#!/bin/bash

# --- Configuration ---
# Match your g++ version (v13.3.0 requires gcov-13)
GCOV_TOOL="/usr/bin/gcov-13" 
BUILD_DIR=build
TEST_EXEC="${BUILD_DIR}/test_number_to_string"
REPORT_DIR=coverage_report
COVERAGE_INFO="${BUILD_DIR}/coverage.info"
TEMP_COVERAGE_INFO="${BUILD_DIR}/coverage.info.tmp"

# Check if the correct gcov tool exists
if [ ! -f "$GCOV_TOOL" ]; then
echo "ERROR: Required gcov tool '$GCOV_TOOL' not found. Ensure gcov-13 is installed."
exit 1
fi

echo "--- 1. Cleaning up old data and running all tests ---"

# Remove previous run-time coverage data (.gcda files)
find . -name '*.gcda' -exec rm {} \;

# Run ALL tests to generate maximum coverage data (.gcda files)
if [ -x "$TEST_EXEC" ]; then
    echo "Running full test suite: ${TEST_EXEC}"
    "$TEST_EXEC"
    TEST_RESULT=$?
    if [ $TEST_RESULT -ne 0 ]; then
        echo "WARNING: Tests failed with exit code $TEST_RESULT. Proceeding with coverage capture."
    fi
else
    echo "ERROR: Test executable '$TEST_EXEC' not found or not executable. Aborting."
    exit 1
fi

echo "--- 2. Capturing cumulative coverage data ---"

# Capture cumulative coverage data from the entire workspace
lcov --gcov-tool "$GCOV_TOOL" \
    --capture \
    --directory "." \
    --output-file "$TEMP_COVERAGE_INFO" \
    --base-directory "." \
    --rc lcov_branch_coverage=1 \
    --rc geninfo_unexecuted_blocks=1 \
    --ignore-errors mismatch,empty \
    --no-checksum 2> /dev/null

echo "--- 3. Filtering and saving final tracefile for AI analysis ---"

# Filter out system headers, test code, and gtest files from the temporary file.
lcov --gcov-tool "$GCOV_TOOL" \
    --remove "$TEMP_COVERAGE_INFO" \
    '*/usr/include/*' \
    '*/gtest/*' \
    '*/tests/*' \
    '*/ai_generated_tests.cpp' \
    --output-file "$COVERAGE_INFO" \
    --ignore-errors unused,empty,mismatch,gcov \
    2> /dev/null

# Clean up temporary file
rm "$TEMP_COVERAGE_INFO"

echo "--- 4. Generating final HTML Report ---"

# Generate the HTML report from the single, final coverage.info file
rm -rf "$REPORT_DIR"
genhtml "$COVERAGE_INFO" \
    --output-directory "$REPORT_DIR" \
    --demangle-cpp \
    --legend \
    --title "Code Coverage Report" \
    --ignore-errors source

echo "--- Done ---"
echo "Summary coverage report generated in $REPORT_DIR/index.html"

# Note: The test_list logic and the for loop were removed as they conflict with 
# the pipeline's requirement for a single cumulative report.
