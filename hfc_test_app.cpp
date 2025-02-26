#include <boost/algorithm/string.hpp>
#include <iostream>
#include <string>
#include <vector>

int main(int argc, char** argv) {

  if(argc < 2) {
    std::cout << "Needs at least one argument" << std::endl;
    return 1;
  }
  
  std::vector<std::string> all_args(argv, argv + argc);
  std::string joined = boost::algorithm::join(all_args, " ");

  std::cout << "These were the arguments to this program: " << joined << std::endl;
  return 0;
}