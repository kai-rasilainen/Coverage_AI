
#include "../src/number_to_string.h"
#include <gtest/gtest.h>

TEST(NullTest, NumberToStringNegative) {
  EXPECT_EQ("NEGATIVE: -1", number_to_string(-1));
}

TEST(NullTest, NumberToStringZero) {
  EXPECT_EQ("NULL", number_to_string(0));
}
TEST(NullTest, NumberToStringPositive) {
  EXPECT_EQ("POSITIVE: 1", number_to_string(1));
}

TEST(NumberGroupTest, NumberToStringNegativeGroup) {
  EXPECT_EQ("GROUP: NEGATIVE: -1", number_to_string(-1, "GROUP"));
}
TEST(NumberGroupTest, NumberToStringZeroGroup) {
  EXPECT_EQ("GROUP: NULL", number_to_string(0, "GROUP"));
}
TEST(NumberGroupTest, NumberToStringPositiveGroup) {
  EXPECT_EQ("GROUP: POSITIVE: 1", number_to_string(1, "GROUP"));
}

TEST(ReturnNumberVariant1Test, ReturnNumberVariant1Negative) {
  EXPECT_EQ("NEGATIVE1: str-1", returnNumberVariant1("str", -1));
}
TEST(ReturnNumberVariant1Test, ReturnNumberVariant1Zero) {
  EXPECT_EQ("NULL1: str", returnNumberVariant1("str", 0));
}
TEST(ReturnNumberVariant1Test, ReturnNumberVariant1Positive) {
  EXPECT_EQ("POSITIVE1: str1", returnNumberVariant1("str", 1));
}

TEST(ReturnNumberVariant2Test, ReturnNumberVariant2Negative) {
  EXPECT_EQ("NEGATIVE2: str-1", returnNumberVariant2("str", -1));
}
TEST(ReturnNumberVariant2Test, ReturnNumberVariant2Zero) {
  EXPECT_EQ("NULL2: str", returnNumberVariant2("str", 0));
}
TEST(ReturnNumberVariant2Test, ReturnNumberVariant2Positive) {
  EXPECT_EQ("POSITIVE2: str1", returnNumberVariant2("str", 1));
}

TEST(ReturnNumberVariant3Test, ReturnNumberVariant3Negative) {
  EXPECT_EQ("NEGATIVE3: str-1", returnNumberVariant3("str", -1));
}
TEST(ReturnNumberVariant3Test, ReturnNumberVariant3Zero) {
  EXPECT_EQ("NULL3: str", returnNumberVariant3("str", 0));
}
TEST(ReturnNumberVariant3Test, ReturnNumberVariant3Positive) {
  EXPECT_EQ("POSITIVE3: str1", returnNumberVariant3("str", 1));
}

TEST(ReturnNumberVariant4Test, ReturnNumberVariant4Negative) {
  EXPECT_EQ("NEGATIVE4: str-1", returnNumberVariant4("str", -1));
}
TEST(ReturnNumberVariant4Test, ReturnNumberVariant4Zero) {
  EXPECT_EQ("NULL4: str", returnNumberVariant4("str", 0));
}
TEST(ReturnNumberVariant4Test, ReturnNumberVariant4Positive) {
  EXPECT_EQ("POSITIVE4: str1", returnNumberVariant4("str", 1));
}

TEST(ReturnNumberVariant5Test, ReturnNumberVariant5Negative) {
  EXPECT_EQ("NEGATIVE5: str-1", returnNumberVariant5("str", -1));
}
TEST(ReturnNumberVariant5Test, ReturnNumberVariant5Zero) {
  EXPECT_EQ("NULL5: str", returnNumberVariant5("str", 0));
}
TEST(ReturnNumberVariant5Test, ReturnNumberVariant5Positive) {
  EXPECT_EQ("POSITIVE5: str1", returnNumberVariant5("str", 1));