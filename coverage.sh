#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Run the 'make test' command to build and run the test executable.
make test

# Check if the executable exists before trying to run it.
if [ ! -f "build/test_number_to_string" ]; then
    echo "Error: The test executable 'build/test_number_to_string' was not found."
    exit 1
fi

# Set directories for coverage reports
BUILD_DIR=build
REPORT_DIR=reports

# Remove previous coverage data and create a new directory
rm -fr ${REPORT_DIR}
mkdir -p ${REPORT_DIR}

# LCOV and genhtml commands for coverage generation
# Use 'lcov --gcov-tool' to specify the gcov command for your version of g++
lcov --capture --directory ${BUILD_DIR} --output-file ${REPORT_DIR}/coverage.info \
--ignore-errors mismatch,inconsistent,unsupported

# Remove system headers and test files from the report
lcov --remove ${REPORT_DIR}/coverage.info '/usr/*' '*/tests/*' --output-file ${REPORT_DIR}/coverage.info

# Generate the HTML report
genhtml ${REPORT_DIR}/coverage.info --output-directory ${REPORT_DIR} --ignore-errors mismatch

echo "Coverage report generated in ${REPORT_DIR}/index.html"

# Clean up
find . -name "*.gcno" -exec rm {} \;
find . -name "*.gcda" -exec rm {} \;
