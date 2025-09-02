#ifndef NUMBER_TO_STRING_H
#define NUMBER_TO_STRING_H

#include <string>

class NumberGroup {
public:
	int number;
	std::string group;
	NumberGroup(int num, const std::string& grp);
};

std::string numberToString(const int number);
std::string numberToString(const NumberGroup& ng);
std::string returnNumberVariant1(const std::string& str, const int number);
std::string returnNumberVariant2(const std::string& str, const int number);
std::string returnNumberVariant3(const std::string& str, const int number);
std::string returnNumberVariant4(const std::string& str, const int number);
std::string returnNumberVariant5(const std::string& str, const int number);

#endif // NUMBER_TO_STRING_H
