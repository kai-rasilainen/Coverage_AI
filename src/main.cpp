#include <iostream>
#include "number_to_string.h"

int main(int argc, char* argv[]) {
    if (argc < 3) {
        std::cerr << "Usage: " << argv[0] << " <integer_value> <group>" << std::endl;
        return 1;
    }
    const int value = std::stoi(argv[1]);
    const std::string group = argv[2];
    const NumberGroup ng(value, group);
    const std::string resultCase1 = numberToString(value);
    std::cout << "CASE1: The number as a string: " << resultCase1 << std::endl;
    const std::string resultCase2 = numberToString(ng);
    std::cout << "CASE2: The number as a string: " << resultCase2 << std::endl;
    const std::string resultCase3 = returnNumberVariant1("FOO1", 11);
    std::cout << "CASE3: " << resultCase3 << std::endl;
    const std::string resultCase4 = returnNumberVariant2("FOO2", 22);
    std::cout << "CASE4: " << resultCase4 << std::endl;
    const std::string resultCase5 = returnNumberVariant3("FOO3", 33);
    std::cout << "CASE5: " << resultCase5 << std::endl;
    const std::string resultCase6 = returnNumberVariant4("FOO4", 44);
    std::cout << "CASE6: " << resultCase6 << std::endl;
    const std::string resultCase7 = returnNumberVariant5("FOO5", 55);
    std::cout << "CASE7: " << resultCase7 << std::endl;

    return 0;
}
