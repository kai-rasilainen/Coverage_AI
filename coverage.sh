#!/bin/bash

# Run tests to generate .gcda and .gcno files
# The 'set -e' command ensures that the script will exit immediately if any command fails.
set -e

make tests

# Check if the make command succeeded and the executable exists
if [ ! -f "build/test_number_to_string" ]; then
    echo "Error: The test executable 'build/test_number_to_string' was not found."
    echo "Please check the 'make tests' command in your Makefile and Jenkins build log for errors."
    exit 1
fi

# The output of g++ is redirected to a temporary file to avoid cluttering the Jenkins console.
test_list=$(build/test_number_to_string --gtest_list_tests | awk '/^[^ ]/ {suite=$1} /^[ ]/ {print suite $1}')

BUILD_DIR=build
REPORT_DIR=reports

for test_case_name in $test_list; do
    COVERAGE_DIR=${REPORT_DIR}/coverage_report_${test_case_name}
    COVERAGE_INFO=${COVERAGE_DIR}/coverage.info
    rm -fr ${COVERAGE_DIR} ; mkdir -p ${COVERAGE_DIR}
    echo "Running test: ${test_case_name} coverage to ${COVERAGE_DIR}"

    lcov --directory build --zerocounters > /dev/null
    build/test_number_to_string --gtest_filter="${test_case_name}" || echo "Test ${test_case_name} failed"

    # Corrected lcov command with flags to ignore errors
    lcov --capture --directory ${BUILD_DIR} --output-file ${COVERAGE_INFO} --ignore-errors unsupported,inconsistent > /dev/null

    # Corrected lcov command to remove system files and test files from the report
    lcov --ignore-errors unused,empty,inconsistent --remove ${COVERAGE_INFO} '/usr/*' '*/tests/*' --output-file ${COVERAGE_INFO} > /dev/null

    # Corrected genhtml command with flags to ignore errors
    genhtml ${COVERAGE_INFO} --output-directory ${COVERAGE_DIR} --ignore-errors missing > /dev/null
    echo "Coverage report generated in ${COVERAGE_DIR}/index.html"
done
