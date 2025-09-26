# Function Specification: numberToString

The `numberToString` function converts an integer input into a string based on the following rules:

1.  **Positive Input (N > 0):** Returns the string "POSITIVE: " followed by the number.
    * *Example:* `numberToString(123)` returns `"POSITIVE: 123"`
2.  **Negative Input (N < 0):** Returns the string "NEGATIVE: " followed by the number.
    * *Example:* `numberToString(-456)` returns `"NEGATIVE: -456"`
3.  **Zero Input (N = 0):** Returns the string `"NULL"`.
