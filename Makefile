# Compiler and flags
CXX = g++
GCOV_FLAGS = --coverage
CXXFLAGS = -std=c++20 -Wall -Wextra -I./src
# New value (with ABI fix):
CXXFLAGS_GTEST = -std=c++20 -Wall -Wextra -I./src -I/usr/include/gtest -D_GLIBCXX_USE_CXX11_ABI=0 -fprofile-dir=$(BUILD_DIR)
GTEST = /usr/local/lib/libgtest_main.a /usr/local/lib/libgtest.a
SRC = src/main.cpp src/number_to_string.cpp
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
	mkdir -p $(BUILD_DIR) # Ensure this is a TAB

# Build the main application
$(TARGET): $(SRC)
	$(CXX) $(CXXFLAGS) -o $@ $(SRC) # Ensure this is a TAB

# ---------------------------------
# CORRECTED: Build the test executable rule (REMOVED -lpthread)
# ---------------------------------
$(TEST_BINARY): $(BUILD_DIR) $(TEST_SRC)
	# Correct Order: Source Files -> GTest Libraries -> Std C++ Library -> Thread Library
	$(CXX) $(CXXFLAGS_GTEST) $(GCOV_FLAGS) \
	-o build/test_number_to_string tests/test_number_to_string.cpp tests/ai_generated_tests.cpp src/number_to_string.cpp \
	-lgtest -lgtest_main -lstdc++ -lpthread

# Clean up
clean:
	rm -rf $(BUILD_DIR) # Ensure this is a TAB

# A new test target that your coverage script can use
test: $(TEST_BINARY)
	./$(TEST_BINARY) # Ensure this is a TAB