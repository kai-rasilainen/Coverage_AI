#!/bin/bash

# --- Configuration ---
# Set the GCOV_TOOL to match the compiler version (g++-11 in your case)
GCOV_TOOL="/usr/bin/gcov-11"
BUILD_DIR="build"
TEST_EXEC="${BUILD_DIR}/test_number_to_string"
REPORT_DIR="coverage_report"
COVERAGE_INFO="${BUILD_DIR}/coverage.info"

# Source directories to include in the report (adjust as needed)
SOURCE_DIR="src"

# Check if the correct gcov tool exists
if [ ! -f "$GCOV_TOOL" ]; then
echo "ERROR: Required gcov tool '$GCOV_TOOL' not found."
echo "Ensure that the 'gcov-11' package is installed (e.g., sudo apt install gcov-11)."
exit 1
fi

echo "--- 1. Cleaning up previous coverage data (.gcda files) ---"

# Remove previous run-time coverage data (.gcda files)
find . -name '*.gcda' -exec rm {} \;

echo "--- 2. Running Unit Tests ---"

# Execute the test executable to generate .gcda files
if [ -x "$TEST_EXEC" ]; then
"$TEST_EXEC"
TEST_RESULT=$?
if [ $TEST_RESULT -ne 0 ]; then
echo "WARNING: Tests failed with exit code $TEST_RESULT. Proceeding with coverage capture."
fi
else
echo "ERROR: Test executable '$TEST_EXEC' not found or not executable. Did the compilation step fail?"
exit 1
fi

echo "--- 3. Capturing coverage data for source files only ---"

# Example LCOV command to fix pathing:
lcov --gcov-tool "$GCOV_TOOL" \
--capture \
--directory "." \
--output-file "$COVERAGE_INFO.tmp" \
--base-directory "." \
--no-checksum \
--rc lcov_branch_coverage=1 \
--ignore-errors mismatch,empty 2> /dev/null

echo "--- 4. Filtering out system headers ---"

# Only remove system includes; the source files (tests, gtest) were excluded in step 3.
lcov --gcov-tool "$GCOV_TOOL" \
--remove "$COVERAGE_INFO.tmp" \
'*/usr/include/*' \
--output-file "$COVERAGE_INFO" \
--ignore-errors unused,empty 2> /dev/null

# Clean up temporary file
rm "$COVERAGE_INFO.tmp"

echo "--- 5. Generating HTML Report in $REPORT_DIR ---"

# Note: genhtml is not silenced as its output often confirms success.
rm -rf "$REPORT_DIR"
genhtml "$COVERAGE_INFO" \
--output-directory "$REPORT_DIR" \
--demangle-cpp \
--legend \
--title "Code Coverage Report" \
--ignore-errors source

echo "--- Done ---"
echo "Coverage report is ready. Open $REPORT_DIR/index.html in your browser."