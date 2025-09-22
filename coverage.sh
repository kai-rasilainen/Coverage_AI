#!/bin/bash

# This script runs all C++ tests and generates a code coverage report using lcov.

# Exit immediately if any command fails.
set -e

# Run the 'make all' command to build the main and test executables.
# The `make` command is expected to create the test executable in the build directory.
make all

# Get a list of all test cases from the test executable.
# The 'awk' command filters the output to capture both the test suite and test case names.
test_list=$(build/test_number_to_string --gtest_list_tests | awk '/^[^ ]/ {suite=$1} /^[ ]/ {print suite $1}')

BUILD_DIR=build
REPORT_DIR=reports

for test_case_name in $test_list; do
    COVERAGE_DIR=${REPORT_DIR}/coverage_report_${test_case_name}
    COVERAGE_INFO=${COVERAGE_DIR}/coverage.info
    rm -fr ${COVERAGE_DIR} ; mkdir -p ${COVERAGE_DIR}
    echo "Running test: ${test_case_name} coverage to ${COVERAGE_DIR}"

    # Reset all counters in the code to zero before running the test.
    lcov --directory build --zerocounters > /dev/null

    # Run the specific test case using --gtest_filter.
    # The '|| echo' part ensures the script doesn't exit on a test failure.
    build/test_number_to_string --gtest_filter="${test_case_name}" || echo "Test ${test_case_name} failed"

    # Capture the coverage data and save it to a .info file.
    # The ignore flags are added to handle compatibility issues with some GCC versions.
    lcov --capture --directory ${BUILD_DIR} --output-file ${COVERAGE_INFO} \
    --ignore-errors mismatch,unused,empty --ignore-errors inconsistent,unsupported > /dev/null

    # Remove irrelevant coverage data from standard libraries and test files.
    lcov --remove ${COVERAGE_INFO} '/usr/*' '*/tests/*' --output-file ${COVERAGE_INFO} > /dev/null
    
    # Generate the HTML report from the coverage data.
    # The ignore flag is for handling potential missing files from lcov step.
    genhtml ${COVERAGE_INFO} --output-directory ${COVERAGE_DIR} --ignore-errors missing > /dev/null
    echo "Coverage report generated in ${COVERAGE_DIR}/index.html"
done
