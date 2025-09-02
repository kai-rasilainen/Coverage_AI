#include "number_to_string.h"
#include <string>

NumberGroup::NumberGroup(int num, const std::string& grp) : number(num), group(grp) {}

std::string numberToString(const int number) {
    if (number < 0) {
        return "NEGATIVE: " + std::to_string(number);
    } else if (number == 0) {
        return std::string("NULL");
    } else {
        return "POSITIVE: " + std::to_string(number);
    }
}
std::string numberToString(const NumberGroup& ng) {
    if (ng.number < 0) {
        return ng.group + ": NEGATIVE: " + std::to_string(ng.number);
    } else if (ng.number == 0) {
        return ng.group + ": NULL";
    } else {
        return ng.group + ": POSITIVE: " + std::to_string(ng.number);
    }
}

std::string returnNumberVariant1(const std::string& str, const int number) {
    if (number < 0) {
        return "NEGATIVE1: " + str + std::to_string(number);
    } else if (number == 0) {
        return std::string("NULL1: ") + str;
    } else {
        return "POSITIVE1: " + str + std::to_string(number);
    }
}

std::string returnNumberVariant2(const std::string& str, const int number) {
    if (number < 0) {
        return "NEGATIVE2: " + str + std::to_string(number);
    } else if (number == 0) {
        return std::string("NULL2: ") + str;
    } else {
        return "POSITIVE2: " + str + std::to_string(number);
    }
}
std::string returnNumberVariant3(const std::string& str, const int number) {
    if (number < 0) {
        return "NEGATIVE3: " + str + std::to_string(number);
    } else if (number == 0) {
        return std::string("NULL3: ") + str;
    } else {
        return "POSITIVE3: " + str + std::to_string(number);
    }
}
std::string returnNumberVariant4(const std::string& str, const int number) {
    if (number < 0) {
        return "NEGATIVE4: " + str + std::to_string(number);
    } else if (number == 0) {
        return std::string("NULL4: ") + str;
    } else {
        return "POSITIVE4: " + str + std::to_string(number);
    }
}
std::string returnNumberVariant5(const std::string& str, const int number) {
    if (number < 0) {
        return "NEGATIVE5: " + str + std::to_string(number);
    } else if (number == 0) {
        return std::string("NULL5: ") + str;
    } else {
        return "POSITIVE5: " + str + std::to_string(number);
    }
}