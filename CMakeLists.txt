# Set minimum required version
cmake_minimum_required(VERSION 3.25)

# Set the project name
project(Coverage_AI CXX)

# Set C++ Standard 20 (instead of CXXFLAGS = -std=c++20)
set(CMAKE_CXX_STANDARD 20)

# 1. Find the required Google Test package
include(FetchContent)

# Define where to fetch GTest source (use a known stable release)
FetchContent_Declare(
    googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG v1.14.0 # A stable, recent release
)

# Fetch and populate GTest source code
FetchContent_MakeAvailable(googletest)

# NOTE: The targets change from 'GTest::gtest_main' to 'gtest_main'
# The dependency on gmock is often implicit when building the combined source.

# 2. Define the source directory and include files
include_directories(src)


# 3. Define the test executable target
add_executable(
    test_number_to_string
    src/number_to_string.cpp
    tests/test_number_to_string.cpp
    tests/ai_generated_tests.cpp
)

set_target_properties(test_number_to_string PROPERTIES
    # Instructs gcov to generate paths relative to the source file location.
    # This is the most reliable way to fix LCOV path mapping in CMake projects.
    COMPILE_FLAGS "-fprofile-dir=."
)

# 4. Link the target to the GTest libraries
# Link libraries now uses the targets created by FetchContent
target_link_libraries(
    test_number_to_string
    gtest_main
)

# 5. Enable coverage (instead of GCOV_FLAGS = --coverage)
target_compile_options(test_number_to_string PRIVATE --coverage)
target_link_options(test_number_to_string PRIVATE --coverage)
