#!/bin/bash

# Define directories for clarity and easy modification
BUILD_DIR=build
REPORT_DIR=reports
COVERAGE_INFO=${REPORT_DIR}/coverage.info

# Ensure the build directory exists and tests are compiled
make test || { echo "Error: make test failed. Please fix compilation issues before running coverage." ; exit 1; }

# Step 1: Clean all old coverage data (.gcda files) to ensure a clean slate for the report.
echo "Cleaning old coverage data..."
find ${BUILD_DIR} -name "*.gcda" -delete

# Step 2: Run all tests in a single execution to accumulate a comprehensive coverage dataset.
echo "Running all tests to generate aggregate coverage data..."
./${BUILD_DIR}/test_number_to_string

# Create the main reports directory
mkdir -p ${REPORT_DIR}

# Step 3: Capture coverage data from the build directory into a single .info file.
# We include flags to ignore common errors and warnings that can occur during the capture process.
echo "Capturing coverage data..."
lcov --capture --directory ${BUILD_DIR} --output-file ${COVERAGE_INFO} --ignore-errors mismatched,unsupported,inconsistent,mismatch

# Step 4: Remove irrelevant coverage data (e.g., system headers and test files themselves)
# to focus the report solely on the application code.
echo "Filtering irrelevant files from the coverage report..."
lcov --remove ${COVERAGE_INFO} '/usr/*' '*/tests/*' --output-file ${COVERAGE_INFO}

# Step 5: Generate the final HTML report from the aggregated data.
echo "Generating HTML report..."
genhtml ${COVERAGE_INFO} --output-directory ${REPORT_DIR} --ignore-errors source,unsupported,empty

echo "Aggregated coverage report generated in ${REPORT_DIR}/index.html"




