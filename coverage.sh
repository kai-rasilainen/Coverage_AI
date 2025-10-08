#!/bin/bash

# --- Configuration ---
# Use the generic 'gcov' executable, relying on the system's PATH.
GCOV_TOOL="gcov" 
BUILD_DIR=build
TEST_EXEC="${BUILD_DIR}/test_number_to_string"
REPORT_DIR=coverage_report
COVERAGE_INFO="${BUILD_DIR}/coverage.info"
TEMP_COVERAGE_INFO="${BUILD_DIR}/coverage.info.tmp"

# Source directories to include in the report (adjust as needed)
SOURCE_DIR="src"

# --- REMOVED: Explicit file check for /usr/bin/gcov-13 ---
# The shell will now rely on PATH lookup for 'gcov'.

echo "--- 1. Cleaning up old data and running all tests ---"

# Remove previous run-time coverage data (.gcda files)
find . -name '*.gcda' -exec rm {} \;

echo "--- 2. Running Unit Tests ---"

# Execute the test executable to generate .gcda files
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

echo "--- 3. Capturing cumulative coverage data ---"

# NOTE: The --gcov-tool flag now uses the generic 'gcov' command.
lcov --gcov-tool "$GCOV_TOOL" \
    --capture \
    --directory "." \
    --output-file "$TEMP_COVERAGE_INFO" \
    --base-directory "." \
    --rc lcov_branch_coverage=1 \
    --rc geninfo_unexecuted_blocks=1 \
    --ignore-errors mismatch,empty \
    --no-checksum 2> /dev/null

# ... (Rest of the script remains the same) ...

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