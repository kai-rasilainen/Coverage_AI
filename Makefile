# Compiler and flags
CXX = g++
GCOV_FLAGS = --coverage
CXXFLAGS = -std=c++17 -Wall -Wextra -I./src
CXXFLAGS_GTEST = -std=c++17 -Wall -Wextra -I./src -I/usr/include/gtest

# Executable paths
SRC = src/main.cpp src/number_to_string.cpp
# We need src/number_to_string.cpp in the TEST_SRC list so its code is linked and covered.
TEST_SRC = tests/test_number_to_string.cpp tests/ai_generated_tests.cpp src/number_to_string.cpp
BUILD_DIR = build
TARGET = $(BUILD_DIR)/main
TEST_BINARY = $(BUILD_DIR)/test_number_to_string

# -----------------
# REMOVED: GTEST variable with the hardcoded path.
# We will link using linker flags (-lgtest -lgtest_main -lpthread) instead.
# -----------------

# Default rule
all: $(BUILD_DIR) $(TARGET) $(TEST_BINARY)

# Create the build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Build the main application
$(TARGET): $(SRC)
	$(CXX) $(CXXFLAGS) -o $@ $(SRC)

# ---------------------------------
# CORRECTED: Build the test executable rule
# ---------------------------------
$(TEST_BINARY): $(BUILD_DIR) $(TEST_SRC)
	# IMPORTANT: Linker requires source files (or object files) that call GTest 
	# functions to appear BEFORE the GTest libraries.
	$(CXX) $(CXXFLAGS_GTEST) $(GCOV_FLAGS) \
	-o $@ $(TEST_SRC) \
	-lgtest -lgtest_main -lpthread

# Clean up
clean:
	rm -rf $(BUILD_DIR)

# A new test target that your coverage script can use
test: $(TEST_BINARY)
	./$(TEST_BINARY)
