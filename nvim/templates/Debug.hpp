#pragma once

#include <iostream>
#include <ranges>
#include <string_view>
#include <tuple>
#include <utility>

// ── Concepts
// ──────────────────────────────────────────────────────────────────
//
// map_like: any associative container with key/mapped types (map,
// unordered_map,
//           multimap, unordered_multimap, …)
// printable_range: any range that isn't a string or map — catches vector,
// array,
//                  set, deque, span, custom ranges, etc. in one overload.

template <typename T>
concept MapLike = requires {
  typename T::key_type;
  typename T::mapped_type;
};

template <typename T>
concept PrintableRange =
    std::ranges::range<T> && !std::is_convertible_v<T, std::string_view> &&
    !MapLike<T>;

// ── Pair ──────────────────────────────────────────────────────────────
template <typename T, typename U>
std::ostream& operator<<(std::ostream& os, const std::pair<T, U>& p) {
  return os << '(' << p.first << ", " << p.second << ')';
}

// ── Tuple ──────────────────────────────────────────────────────────────
// std::apply + a fold expression replaces the recursive TuplePrinter struct.
template <typename... Args>
std::ostream& operator<<(std::ostream& os, const std::tuple<Args...>& tup) {
  os << '(';
  std::apply(
      [&os](const auto&... args) {
        std::size_t i = 0;
        ((os << (i++ ? ", " : "") << args), ...);
      },
      tup);
  return os << ')';
}

// ── Maps ──────────────────────────────────────────────────────────────
template <MapLike M>
std::ostream& operator<<(std::ostream& os, const M& mp) {
  os << '{';
  bool first = true;
  for (const auto& [k, v] : mp) {
    if (!first) {
      os << ", ";
    }
    os << k << ": " << v;
    first = false;
  }
  return os << '}';
}

// ── Sequential Ranges ──────────────────────────────────────────────────────
template <PrintableRange R>
std::ostream& operator<<(std::ostream& os, const R& r) {
  os << '[';
  bool first = true;
  for (const auto& elem : r) {
    if (!first) {
      os << ", ";
    }
    os << elem;
    first = false;
  }
  return os << ']';
}

namespace detail {

inline void debugImpl(std::string_view names, auto&& val) {
  std::cout << names << " = " << val << '\n';
}

inline void debugImpl(std::string_view names, auto&& val, auto&&... rest) {
  const auto comma = names.find(',');
  std::cout << names.substr(0, comma) << " = " << val << '\n';
  // skip ", " (two characters) after the comma
  debugImpl(names.substr(comma + 2), std::forward<decltype(rest)>(rest)...);
}

}  // namespace detail

#define DEBUG(...) detail::debugImpl(#__VA_ARGS__, __VA_ARGS__)
