Requirements Specification: numberToString

The C++ function std::string numberToString(long long number) converts an integer input into a string based on the following rules.

The resulting string must include both the prefix and the number value, exactly as specified below:
1. Zero Handling

    Input: 0

    Expected Output (String Literal): "NULL"

2. Positive Number Handling

    Input: Any positive integer ($ > 0 $).

    Expected Output Format: The string "POSITIVE: " followed immediately by the string representation of the number.

    Examples:

        numberToString(123) must return "POSITIVE: 123"

        numberToString(2147483647) (INT_MAX) must return "POSITIVE: 2147483647"

        numberToString(9223372036854775807LL) (LLONG_MAX) must return "POSITIVE: 9223372036854775807"

3. Negative Number Handling

    Input: Any negative integer ($ < 0 $).

    Expected Output Format: The string "NEGATIVE: " followed immediately by the string representation of the number, including the minus sign.

    Examples:

        numberToString(-45) must return "NEGATIVE: -45"

        numberToString(-2147483648) (INT_MIN) must return "NEGATIVE: -2147483648"

        numberToString(-9223372036854775808LL) (LLONG_MIN) must return "NEGATIVE: -9223372036854775808"

Requirements Specification: returnNumberVariant1

The C++ function std::string returnNumberVariant1(const std::string& str, const int number) modifies the input string str based on the value of number.
1. Zero Handling (Variant 1)

    Prefix: "NULL1: "

    Logic: Returns Prefix + input string str. The integer number is NOT appended.

    Example:

        returnNumberVariant1("data", 0) must return "NULL1: data"

2. Positive Number Handling (Variant 1)

    Prefix: "POSITIVE1: "

    Logic: Returns Prefix + input string str + string representation of number.

    Example:

        returnNumberVariant1("data", 10) must return "POSITIVE1: data10"

3. Negative Number Handling (Variant 1)

    Prefix: "NEGATIVE1: "

    Logic: Returns Prefix + input string str + string representation of number (including the minus sign).

    Example:

        returnNumberVariant1("data", -10) must return "NEGATIVE1: data-10"

Requirements Specification: returnNumberVariant2

The C++ function std::string returnNumberVariant2(const std::string& str, const int number) follows the exact same logic as Variant 1, but uses the '2' prefix.
1. Zero Handling (Variant 2)

    Prefix: "NULL2: "

    Logic: Returns Prefix + input string str.

    Example:

        returnNumberVariant2("data", 0) must return "NULL2: data"

2. Positive Number Handling (Variant 2)

    Prefix: "POSITIVE2: "

    Logic: Returns Prefix + input string str + string representation of number.

    Example:

        returnNumberVariant2("data", 10) must return "POSITIVE2: data10"

3. Negative Number Handling (Variant 2)

    Prefix: "NEGATIVE2: "

    Logic: Returns Prefix + input string str + string representation of number (including the minus sign).

    Example:

        returnNumberVariant2("data", -10) must return "NEGATIVE2: data-10"

Requirements Specification: returnNumberVariant3

The C++ function std::string returnNumberVariant3(const std::string& str, const int number) follows the exact same logic as Variant 1, but uses the '3' prefix.
1. Zero Handling (Variant 3)

    Prefix: "NULL3: "

    Logic: Returns Prefix + input string str.

    Example:

        returnNumberVariant3("data", 0) must return "NULL3: data"

2. Positive Number Handling (Variant 3)

    Prefix: "POSITIVE3: "

    Logic: Returns Prefix + input string str + string representation of number.

    Example:

        returnNumberVariant3("data", 10) must return "POSITIVE3: data10"

3. Negative Number Handling (Variant 3)

    Prefix: "NEGATIVE3: "

    Logic: Returns Prefix + input string str + string representation of number (including the minus sign).

    Example:

        returnNumberVariant3("data", -10) must return "NEGATIVE3: data-10"

Requirements Specification: returnNumberVariant4

The C++ function std::string returnNumberVariant4(const std::string& str, const int number) follows the exact same logic as Variant 1, but uses the '4' prefix.
1. Zero Handling (Variant 4)

    Prefix: "NULL4: "

    Logic: Returns Prefix + input string str.

    Example:

        returnNumberVariant4("data", 0) must return "NULL4: data"

2. Positive Number Handling (Variant 4)

    Prefix: "POSITIVE4: "

    Logic: Returns Prefix + input string str + string representation of number.

    Example:

        returnNumberVariant4("data", 10) must return "POSITIVE4: data10"

3. Negative Number Handling (Variant 4)

    Prefix: "NEGATIVE4: "

    Logic: Returns Prefix + input string str + string representation of number (including the minus sign).

    Example:

        returnNumberVariant4("data", -10) must return "NEGATIVE4: data-10"

Requirements Specification: returnNumberVariant5

The C++ function std::string returnNumberVariant5(const std::string& str, const int number) follows the exact same logic as Variant 1, but uses the '5' prefix.
1. Zero Handling (Variant 5)

    Prefix: "NULL5: "

    Logic: Returns Prefix + input string str.

    Example:

        returnNumberVariant5("data", 0) must return "NULL5: data"

2. Positive Number Handling (Variant 5)

    Prefix: "POSITIVE5: "

    Logic: Returns Prefix + input string str + string representation of number.

    Example:

        returnNumberVariant5("data", 10) must return "POSITIVE5: data10"

3. Negative Number Handling (Variant 5)

    Prefix: "NEGATIVE5: "

    Logic: Returns Prefix + input string str + string representation of number (including the minus sign).

    Example:

        returnNumberVariant5("data", -10) must return "NEGATIVE5: data-10"