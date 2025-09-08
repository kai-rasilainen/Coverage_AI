#!/bin/bash

# Define directories for clarity and easy modification
BUILD_DIR=build
REPORT_DIR=reports

# Ensure the build directory exists and tests are compiled
make test || { echo "Error: make test failed. Please fix compilation issues before running coverage." ; exit 1; }

# Get the list of all individual tests to run
# The awk command correctly parses the gtest_list_tests output
test_list=$(./${BUILD_DIR}/test_number_to_string --gtest_list_tests | awk '/^[^ ]/ {suite=$1} /^[ ]/ {print suite $1}')

# Check if the test list is empty, which indicates a problem
if [ -z "$test_list" ]; then
    echo "Error: Could not retrieve test list from build/test_number_to_string. Is the executable present and working?"
    exit 1
fi

# Create the main reports directory
mkdir -p ${REPORT_DIR}

for test_case_name in $test_list; do
    # Define a unique directory for each test's report
    COVERAGE_DIR=${REPORT_DIR}/coverage_report_${test_case_name}
    COVERAGE_INFO=${COVERAGE_DIR}/coverage.info

    # Clean up previous report and create a new directory
    rm -fr ${COVERAGE_DIR}
    mkdir -p ${COVERAGE_DIR}

    echo "Running test: ${test_case_name} and generating report in ${COVERAGE_DIR}"

    # Clear previous counter data from all files
    lcov --directory ${BUILD_DIR} --zerocounters

    # Run a single test case using --gtest_filter
    ./${BUILD_DIR}/test_number_to_string --gtest_filter="${test_case_name}"

    # Capture coverage data from the build directory
    # I've included the most common flags to suppress typical geninfo warnings
    lcov --capture --directory ${BUILD_DIR} --output-file ${COVERAGE_INFO} --ignore-errors mismatched,unsupported,inconsistent,mismatch

    # Remove irrelevant coverage data (system includes, tests directory)
    lcov --remove ${COVERAGE_INFO} '/usr/*' '*/tests/*' --output-file ${COVERAGE_INFO}

    # Generate the HTML report
    # The --ignore-errors flag in genhtml takes specific error types.
    genhtml ${COVERAGE_INFO} --output-directory ${COVERAGE_DIR} --ignore-errors source,unsupported,empty

    echo "Coverage report for ${test_case_name} generated in ${COVERAGE_DIR}/index.html"
done


