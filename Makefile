# C++ Compiler
CXX = g++

# GCOV Flags for Test Coverage
GCOV_FLAGS = --coverage

# Common Compiler Flags
CXXFLAGS = -std=c++17 -Wall -Wextra

# Include path for your source files
INCLUDE_PATH = -I./src

# Include and Library paths for Google Test
# -I: points to the directory containing the gtest/gtest.h header
# -L: points to the directory containing the libgtest.a library file
GTEST_INCLUDE_PATH = -I/usr/src/gtest/googletest/include
GTEST_LIB_PATH = -L/usr/src/gtest/build/lib

# Linker flags for GTest
# -l: specifies the name of the library to link against (gtest).
# `pthread` is required for Google Test to work correctly.
GTEST_LDFLAGS = -lgtest -lgtest_main -lpthread

# Build directories
BUILD_DIR = build
SRC_DIR = src
TEST_DIR = tests

# Main source files and executable
MAIN_SRC = $(SRC_DIR)/main.cpp $(SRC_DIR)/number_to_string.cpp
MAIN_TARGET = $(BUILD_DIR)/main

# Test source files and executable
# This uses a wildcard to automatically find all test files in the directory.
TEST_SRC = $(wildcard $(TEST_DIR)/*.cpp)
TEST_OBJ = $(TEST_SRC:.cpp=.o)
TEST_TARGET = $(BUILD_DIR)/test_number_to_string

# Application source files to be linked with tests
APP_SRC_TO_TEST = $(SRC_DIR)/number_to_string.cpp

.PHONY: all clean test coverage

# Default target
all: $(MAIN_TARGET)

# Compile the main application
$(MAIN_TARGET): $(MAIN_SRC) | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $(INCLUDE_PATH) $^ -o $@

# Compile the test executable
$(TEST_TARGET): $(TEST_SRC) $(APP_SRC_TO_TEST) | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $(GCOV_FLAGS) $(INCLUDE_PATH) $(GTEST_INCLUDE_PATH) $(GTEST_LIB_PATH) $^ -o $@ $(GTEST_LDFLAGS)

# Rule to build the test executable and run tests
test: $(TEST_TARGET)
	./$(TEST_TARGET)

# Rule to run the coverage script
coverage:
	./coverage.sh

# Create build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Clean up built files and coverage data
clean:
	rm -rf $(BUILD_DIR) reports
