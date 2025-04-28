#include <array>
#include <cstddef>
#include <cstring>
#include <iostream>
#include <map>
#include <ostream>
#include <tuple>
#include <unordered_map>
#include <utility>
#include <vector>

#ifdef DEBUG
#define debug(...) debugPrint(#__VA_ARGS__, __VA_ARGS__)
#else
#define debug(...)
#endif  // DEBUG

// Array
template <typename T, std::size_t N>
std::ostream& operator<<(std::ostream& os, const std::array<T, N>& arr) {
  for (std::size_t i = 0; i < N; ++i) {
    os << arr[i] << " \n"[i == N - 1];
  }
  return os;
}

// Vector
template <typename T>
std::ostream& operator<<(std::ostream& os, const std::vector<T>& vec) {
  for (std::size_t i = 0; i < vec.size(); ++i) {
    os << vec[i] << " \n"[i == vec.size() - 1];
  }
  return os;
}

template <typename Key, typename Value>
std::ostream& operator<<(std::ostream& os,
                         const std::unordered_map<Key, Value>& mp) {
  os << '{';
  std::size_t i = 0;
  for (const auto& [k, v] : mp) {
    os << '(' << k << ": " << v << ')';
    if (i++ < mp.size() - 1) {
      os << ',';
    }
  }
  return os << "}\n";
}

template <typename Key, typename Value>
std::ostream& operator<<(std::ostream& os, const std::map<Key, Value>& mp) {
  os << '{';
  std::size_t i = 0;
  for (const auto& [k, v] : mp) {
    os << '(' << k << ": " << v << ')';
    if (i++ < mp.size() - 1) {
      os << ',';
    }
  }
  return os << "}\n";
}

// Pair
template <typename T, typename U>
std::ostream& operator<<(std::ostream& os, const std::pair<T, U>& p) {
  return os << '(' << p.first << ',' << p.second << ")\n";
}

// Tuple
template <typename Tuple, std::size_t N>
struct TuplePrinter {
  static void print(std::ostream& os, const Tuple& tup) {
    // recursive call
    TuplePrinter<Tuple, N - 1>::print(os, tup);
    os << ',' << std::get<N - 1>(tup);
  }
};

// Template Specialization for base case.
template <typename Tuple>
struct TuplePrinter<Tuple, 1> {
  static void print(std::ostream& os, const Tuple& tup) {
    os << std::get<0>(tup);
  }
};

template <typename... Args>
std::ostream& operator<<(std::ostream& os, std::tuple<Args...> tup) {
  os << '(';
  TuplePrinter<decltype(tup), sizeof...(Args)>::print(os, tup);
  return os << ")\n";
}

template <typename T>
void debugPrint(const char* name, T&& val) {
  std::clog << name << ": " << val << '\n';
}

template <typename T, typename... Rest>
void debugPrint(const char* names, T&& val, Rest&&... rest) {
  const char* comma = strchr(names, ',');
  std::clog.write(names, comma - names) << ": " << val << '\n';
  debugPrint(comma + 1, std::forward<Rest>(rest)...);
}
