#!/bin/bash

make tests
test_list=$(build/test_number_to_string --gtest_list_tests | awk '/^[^ ]/ {suite=$1} /^[ ]/ {print suite $1}')

BUILD_DIR=build
REPORT_DIR=reports

for test_case_name in $test_list; do
    COVERAGE_DIR=${REPORT_DIR}/coverage_report_${test_case_name}
    COVERAGE_INFO=${COVERAGE_DIR}/coverage.info
    rm -fr ${COVERAGE_DIR} ; mkdir -p ${COVERAGE_DIR}
    echo "Running test: ${test_case_name} coverage to ${COVERAGE_DIR}"

    lcov --directory build --zerocounters > /dev/null
    build/test_number_to_string --gtest_filter="${test_case_name}" || echo "Test ${test_case_name failed}"
    lcov --capture --directory ${BUILD_DIR} --output-file ${COVERAGE_INFO} --ignore-errors mismatch,unsupported,inconsistent > /dev/null
    lcov --ignore-errors unused,empty,inconsistent --remove ${COVERAGE_INFO} '/usr/*' '*/tests/*' --output-file ${COVERAGE_INFO} > /dev/null
    genhtml ${COVERAGE_INFO} --output-directory ${COVERAGE_DIR} --ignore-errors missing > /dev/null
    echo "Coverage report generated in ${COVERAGE_DIR}/index.html"
done