#include "../src/number_to_string.h"
#include <gtest/gtest.h>


// Each test is now a separate case for fine-grained filtering
TEST(NumberToStringObject_Positive, GroupObject) {
    NumberGroup ng(5, "GROUP_A");
    EXPECT_EQ(numberToString(ng), "GROUP_A: POSITIVE: 5");
}
TEST(NumberToStringInt_Positive, Int) {
    EXPECT_EQ(numberToString(10), "POSITIVE: 10");
}

TEST(NumberToStringInt_Negative, GroupObject) {
    NumberGroup ng(-7, "GROUP_B");
    EXPECT_EQ(numberToString(ng), "GROUP_B: NEGATIVE: -7");
}
TEST(NumberToStringInt_Negative, Int) {
    EXPECT_EQ(numberToString(-10), "NEGATIVE: -10");
}

TEST(NumberToStringInt_Zero, GroupObject) {
    NumberGroup ng(0, "GROUP_C");
    EXPECT_EQ(numberToString(ng), "GROUP_C: NULL");
}
TEST(NumberToStringInt_Zero, Int) {
    EXPECT_EQ(numberToString(0), "NULL");
}

TEST(ReturnNumberVariant1, Positive) {
    EXPECT_EQ(returnNumberVariant1("TEST", 5), "POSITIVE1: TEST5");
}
TEST(ReturnNumberVariant1, Negative) {
    EXPECT_EQ(returnNumberVariant1("TEST", -3), "NEGATIVE1: TEST-3");
}
TEST(ReturnNumberVariant1, Zero) {
    EXPECT_EQ(returnNumberVariant1("TEST", 0), "NULL1: TEST");
}

TEST(ReturnNumberVariant2, Positive) {
    EXPECT_EQ(returnNumberVariant2("TEST", 5), "POSITIVE2: TEST5");
}
TEST(ReturnNumberVariant2, Negative) {
    EXPECT_EQ(returnNumberVariant2("TEST", -3), "NEGATIVE2: TEST-3");
}
TEST(ReturnNumberVariant2, Zero) {
    EXPECT_EQ(returnNumberVariant2("TEST", 0), "NULL2: TEST");
}

TEST(ReturnNumberVariant3, Positive) {
    EXPECT_EQ(returnNumberVariant3("TEST", 5), "POSITIVE3: TEST5");
}
TEST(ReturnNumberVariant3, Negative) {
    EXPECT_EQ(returnNumberVariant3("TEST", -3), "NEGATIVE3: TEST-3");
}
TEST(ReturnNumberVariant3, Zero) {
    EXPECT_EQ(returnNumberVariant3("TEST", 0), "NULL3: TEST");
}

TEST(ReturnNumberVariant4, Positive) {
    EXPECT_EQ(returnNumberVariant4("TEST", 5), "POSITIVE4: TEST5");
}
TEST(ReturnNumberVariant4, Negative) {
    EXPECT_EQ(returnNumberVariant4("TEST", -3), "NEGATIVE4: TEST-3");
}
TEST(ReturnNumberVariant4, Zero) {
    EXPECT_EQ(returnNumberVariant4("TEST", 0), "NULL4: TEST");
}

TEST(ReturnNumberVariant5, Positive) {
    EXPECT_EQ(returnNumberVariant5("TEST", 5), "POSITIVE5: TEST5");
}
TEST(ReturnNumberVariant5, Negative) {
    EXPECT_EQ(returnNumberVariant5("TEST", -3), "NEGATIVE5: TEST-3");
}

int main(int argc, char **argv) {
    ::testing::InitGoogleTest(&argc, argv);
    if (argc == 1) {
        std::cout << "RUNNING TESTS ..." << std::endl;
        int ret{RUN_ALL_TESTS()};
        if (!ret)
            std::cout << "<<<SUCCESS>>>" << std::endl;
        else
            std::cout << "FAILED" << std::endl;
        return ret;
    }
    return 0;
}
