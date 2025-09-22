#!/bin/bash

# Run all tests to generate coverage data for each test case.
test_list=$(build/test_number_to_string --gtest_list_tests | awk '/^[^ ]/ {suite=$1} /^[ ]/ {print suite $1}')

BUILD_DIR=build
REPORT_DIR=reports

for test_case_name in $test_list; do
    COVERAGE_DIR=${REPORT_DIR}/coverage_report_${test_case_name}
    COVERAGE_INFO=${COVERAGE_DIR}/coverage.info
    rm -fr ${COVERAGE_DIR} ; mkdir -p ${COVERAGE_DIR}
    echo "Running test: ${test_case_name} coverage to ${COVERAGE_DIR}"

    # Reset counters before each test run
    lcov --directory build --zerocounters > /dev/null

    # Run the specific test case
    build/test_number_to_string --gtest_filter="${test_case_name}" || echo "Test ${test_case_name} failed"

    # Capture coverage data and ignore unsupported and inconsistent errors
    lcov --capture --directory ${BUILD_DIR} --output-file ${COVERAGE_INFO} --ignore-errors mismatch,unsupported,inconsistent > /dev/null

    # Filter out coverage data from system files and test files,
    # and ignore unused or empty errors.
    lcov --ignore-errors unused,empty,inconsistent --remove ${COVERAGE_INFO} '/usr/*' '*/tests/*' --output-file ${COVERAGE_INFO} > /dev/null
    
    # Generate an HTML report and ignore missing file errors
    genhtml ${COVERAGE_INFO} --output-directory ${COVERAGE_DIR} --ignore-errors missing > /dev/null
    echo "Coverage report generated in ${COVERAGE_DIR}/index.html"
done
