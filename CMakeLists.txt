# Set minimum required version
cmake_minimum_required(VERSION 3.25)

# Set the project name
project(Coverage_AI CXX)

# Set C++ Standard 20 (instead of CXXFLAGS = -std=c++20)
set(CMAKE_CXX_STANDARD 20)

# 1. Find the required Google Test package
# This step automatically handles include paths and linking flags.
find_package(GTest REQUIRED)

# 2. Define the source directory and include files
include_directories(src)

# 3. Define the test executable target
add_executable(
    test_number_to_string
    src/number_to_string.cpp
    tests/test_number_to_string.cpp
    tests/ai_generated_tests.cpp
)

# 4. Link the target to the GTest libraries
# Use the automatically imported targets from find_package(GTest)
target_link_libraries(
    test_number_to_string
    GTest::gtest_main
)

# 5. Enable coverage (instead of GCOV_FLAGS = --coverage)
target_compile_options(test_number_to_string PRIVATE --coverage)
target_link_options(test_number_to_string PRIVATE --coverage)
