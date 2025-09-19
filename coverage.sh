#!/bin/bash

# Define build and report directories
BUILD_DIR=build
REPORT_DIR=reports

# Exit immediately if a command exits with a non-zero status.
set -e

# Step 1: Ensure tests are compiled before running coverage.
echo "Compiling tests for coverage analysis..."
make test || { echo "Error: make test failed. Please fix compilation issues before running coverage."; exit 1; }

# Step 2: Run all tests in a single execution to accumulate a comprehensive coverage dataset.
echo "Running all tests to generate aggregate coverage data..."
# Reset counters to avoid stamp mismatch errors from previous runs.
lcov --directory ${BUILD_DIR} --zerocounters
./${BUILD_DIR}/test_number_to_string --gtest_filter="*"

# Step 3: Capture coverage data from the build directory.
echo "Capturing coverage data from build"
# The --ignore-errors flags handle common warnings from gcov output for system headers.
# The --rc flags are used to set options for geninfo.
lcov --directory ${BUILD_DIR} --capture --output-file ${REPORT_DIR}/coverage.info \
    --rc lcov_branch_coverage=1 --rc geninfo_unexecuted_blocks=1 \
    --ignore-errors mismatch,unsupported,inconsistent,gcov,source

# Step 4: Filter out irrelevant files from the coverage report.
echo "Filtering irrelevant files from the coverage report..."
lcov --remove ${REPORT_DIR}/coverage.info '/usr/*' '*/tests/*' \
     --output-file ${REPORT_DIR}/coverage.info \
     --ignore-errors empty

# Step 5: Generate the final HTML report.
echo "Generating HTML report..."
mkdir -p ${REPORT_DIR}
genhtml ${REPORT_DIR}/coverage.info --output-directory ${REPORT_DIR} \
    --ignore-errors empty,source

echo "Aggregated coverage report generated in ${REPORT_DIR}/index.html"

