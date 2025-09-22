# Compiler and flags
CXX = g++
GCOV_FLAGS = --coverage
CXXFLAGS = -std=c++17 -Wall -Wextra -I./src
CXXFLAGS_GTEST = -std=c++17 -Wall -Wextra -I./src -I/usr/include/gtest

# Executable paths
SRC = src/main.cpp src/number_to_string.cpp
TEST_SRC = tests/test_number_to_string.cpp tests/ai_generated_tests.cpp src/number_to_string.cpp
BUILD_DIR = build
TARGET = $(BUILD_DIR)/main
TEST_BINARY = $(BUILD_DIR)/test_number_to_string

# Google Test Library Path
GTEST = /usr/lib/x86_64-linux-gnu/libgtest.a
# For macOS, if using gtest installed via a package manager, the path might be:
# GTEST = /usr/local/lib/libgtest.a

# Default rule
all: $(BUILD_DIR) $(TARGET) $(TEST_BINARY)

# Create the build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Build the main application
$(TARGET): $(SRC)
	$(CXX) $(CXXFLAGS) -o $@ $(SRC)

# Build the test executable
$(TEST_BINARY): $(BUILD_DIR) $(TEST_SRC)
	$(CXX) $(CXXFLAGS_GTEST) $(GCOV_FLAGS) -o $@ $(TEST_SRC) $(GTEST)

# Clean up
clean:
	rm -rf $(BUILD_DIR)

# A new test target that your coverage script can use
test: $(TEST_BINARY)
	./$(TEST_BINARY)
