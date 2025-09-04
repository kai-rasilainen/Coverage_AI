
CXX = g++
GCOV_FLAGS = --coverage
CXXFLAGS = -std=c++17 -Wall -Wextra -I./src
CXXFLAGS_GTEST = -std=c++17 -Wall -Wextra -I./src -I /usr/include/gtest/
GTEST = /opt/homebrew/lib/libgtest.a
SRC = src/main.cpp src/number_to_string.cpp
BUILD_DIR = build
TARGET = $(BUILD_DIR)/main
TEST_SRC = tests/test_number_to_string.cpp src/number_to_string.cpp
TEST_BINARY = $(BUILD_DIR)/test_number_to_string
TEST_BUILD = tests

all: $(BUILD_DIR) $(TARGET) $(TEST_BUILD)

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(TARGET): $(SRC)
	$(CXX) $(CXXFLAGS) -o $@ $(SRC)

$(TEST_BUILD): $(TEST_BINARY)

$(TEST_BINARY): $(BUILD_DIR) $(TEST_SRC)
	$(CXX) $(CXXFLAGS_GTEST) $(GCOV_FLAGS) -o $@ $(TEST_SRC) $(GTEST)

clean:
	rm -rf $(BUILD_DIR)
