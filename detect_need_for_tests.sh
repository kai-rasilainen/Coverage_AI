#!/bin/bash

# precondition: lcov installed, tests built with coverage flags, git repo
# make clean
# make all

# 1. Get changed files from the latest commit (any .cpp or .h* file in any subdirectory)
changed_files=$(git diff-tree --no-commit-id --name-only -r HEAD | grep -E '\.(cpp|h[^/]*)$')

# For testing purposes, you can also use all changes in the working directory
#changed_files=$(git diff --name-only | grep '^src/.*')

echo "Changed files: $changed_files"

if [ -z "$changed_files" ]; then
    echo "No source files changed."
    exit 0
fi

# 2. List all test cases
test_bin=./build/test_number_to_string
test_list=$( $test_bin --gtest_list_tests | awk '/^[^ ]/ {suite=$1} /^[ ]/ {print suite $1}' )

# 3. For each test, check if it covers changed files
affected_tests=() 
for test in $test_list; do
    echo "************************************************"
    echo "Checking test: $test"
    echo "************************************************"
    # Reset coverage counters
    rm -f tmp_coverage.info || true
    lcov --directory build --zerocounters > /dev/null

    # Run only this test
    $test_bin --gtest_filter=$test > /dev/null

    # Capture coverage
    lcov --capture --directory build --output-file tmp_coverage.info  --ignore-errors mismatch > /dev/null
    lcov --ignore-errors unused,unused --ignore-errors empty --remove tmp_coverage.info '/usr/*' '*/tests/*' --output-file tmp_coverage.info

    # Check if any changed file is covered
    for file in $changed_files; do
        if grep -q "$file" tmp_coverage.info; then
            affected_tests+=($test)
            break
        fi
    done
done

rm -f tmp_coverage.info || true

# 4. Output affected tests
if [ ${#affected_tests[@]} -eq 0 ]; then
    echo "No tests affected by changes."
    exit 0
else
    echo "Affected tests:"
    for t in "${affected_tests[@]}"; do
        echo "$t"
    done
    exit 1
fi
