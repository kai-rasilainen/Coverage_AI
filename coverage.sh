#!/bin/bash

# Define build and report directories
BUILD_DIR=build
REPORT_DIR=reports
COVERAGE_INFO_FILE="${REPORT_DIR}/coverage.info"

# Exit immediately if a command exits with a non-zero status.
# We will selectively override this for certain commands.
set -e

# Step 1: Ensure tests are compiled. If not, exit.
echo "Compiling tests for coverage analysis..."
make test || { echo "Error: make test failed. Please fix compilation issues before running coverage."; exit 1; }

# Step 2: Clean up old coverage data and run all tests.
echo "Running all tests to generate aggregate coverage data..."
# Reset counters to avoid 'stamp mismatch' errors from previous runs.
lcov --directory ${BUILD_DIR} --zerocounters || true
# Run the test executable. We use || true to prevent the script from
# exiting if any tests fail, so coverage data can still be collected.
./${BUILD_DIR}/test_number_to_string --gtest_filter="*" || true

# Step 3: Capture coverage data.
echo "Capturing coverage data from build..."
# We use a temporary file to avoid issues with non-existent or empty files.
lcov --directory ${BUILD_DIR} --capture --output-file ${COVERAGE_INFO_FILE}.tmp \
    --rc lcov_branch_coverage=1 --rc geninfo_unexecuted_blocks=1 \
    --no-fail-on-warnings --gcov-tool /usr/bin/gcov

# Ensure the temporary file is not empty before proceeding.
if [ ! -s "${COVERAGE_INFO_FILE}.tmp" ]; then
    echo "Warning: No coverage data captured. Creating empty report."
    touch "${COVERAGE_INFO_FILE}"
else
    # Step 4: Filter out irrelevant files (system headers, test files).
    echo "Filtering irrelevant files from the coverage report..."
    lcov --remove "${COVERAGE_INFO_FILE}.tmp" '/usr/*' '*/tests/*' \
         --output-file "${COVERAGE_INFO_FILE}" \
         --no-fail-on-warnings
fi

# Step 5: Generate the final HTML report.
echo "Generating HTML report..."
mkdir -p ${REPORT_DIR}
genhtml "${COVERAGE_INFO_FILE}" --output-directory ${REPORT_DIR} \
    --no-fail-on-warnings

echo "Aggregated coverage report generated in ${REPORT_DIR}/index.html"
