#pragma once

#include <concepts>
#include <iostream>
#include <type_traits>

// Modular arithmetic wrapper.
//
// Template parameters:
//   T   — underlying signed integer type (default: int)
//   MOD — modulus; must be prime for inverse() and operator/ to be valid
//
// Note: __int128 is used for wide multiplication and requires GCC or Clang.
template <std::signed_integral T = int, T MOD = T{1'000'000'007}>
class ModNum {
  static_assert(MOD > 1, "MOD must be greater than 1");

  using wide_t = std::conditional_t<sizeof(T) <= 4, long long, __int128>;

 public:
  ModNum() noexcept : x(0) {}

  // Implicit construction from any integer type enables natural mixed-mode
  // arithmetic (e.g. ModNum + int) without a forest of templated overloads.
  template <std::integral U>
  ModNum(U v) noexcept {
    x = static_cast<T>(static_cast<wide_t>(v) % MOD);
    if (x < 0) {
      x += MOD;
    }
  }

  [[nodiscard]] constexpr T get() const noexcept { return x; }
  explicit constexpr operator int() const noexcept {
    return static_cast<int>(x);
  }

  explicit constexpr operator long long() const noexcept {
    return static_cast<long long>(x);
  }

  ModNum& operator+=(ModNum rhs) noexcept {
    x += rhs.x;
    if (x >= MOD) {
      x -= MOD;
    }
    return *this;
  }
  ModNum& operator-=(ModNum rhs) noexcept {
    x -= rhs.x;
    if (x < 0) {
      x += MOD;
    }
    return *this;
  }
  ModNum& operator*=(ModNum rhs) noexcept {
    x = static_cast<T>(static_cast<wide_t>(x) * rhs.x % MOD);
    return *this;
  }
  ModNum& operator/=(ModNum rhs) { return *this *= rhs.inverse(); }

  [[nodiscard]] friend ModNum operator+(ModNum lhs, ModNum rhs) noexcept {
    return lhs += rhs;
  }
  [[nodiscard]] friend ModNum operator-(ModNum lhs, ModNum rhs) noexcept {
    return lhs -= rhs;
  }
  [[nodiscard]] friend ModNum operator*(ModNum lhs, ModNum rhs) noexcept {
    return lhs *= rhs;
  }
  [[nodiscard]] friend ModNum operator/(ModNum lhs, ModNum rhs) {
    return lhs /= rhs;
  }

  [[nodiscard]] ModNum operator+() const noexcept { return *this; }
  [[nodiscard]] ModNum operator-() const noexcept {
    return x == 0 ? ModNum() : ModNum(MOD - x);
  }

  ModNum& operator++() noexcept {
    if (++x == MOD) {
      x = 0;
    }
    return *this;
  }
  ModNum& operator--() noexcept {
    if (x == 0) {
      x = MOD - 1;
    } else {
      --x;
    }
    return *this;
  }

  [[nodiscard]] ModNum operator++(int) noexcept {
    ModNum tmp(*this);
    ++*this;
    return tmp;
  }

  [[nodiscard]] ModNum operator--(int) noexcept {
    ModNum tmp(*this);
    --*this;
    return tmp;
  }

  [[nodiscard]] ModNum pow(long long exp) const {
    if (exp < 0) {
      return inverse().pow(-exp);
    }
    ModNum result(1), base(*this);
    for (; exp > 0; exp >>= 1) {
      if (exp & 1) {
        result *= base;
      }
      base *= base;
    }
    return result;
  }

  // Modular inverse via Fermat's little theorem. Requires MOD to be prime.
  [[nodiscard]] ModNum inverse() const {
    return pow(static_cast<long long>(MOD) - 2);
  }

  // Defaulted == also synthesises != in C++20.
  [[nodiscard]] bool operator==(const ModNum&) const noexcept = default;

  friend std::ostream& operator<<(std::ostream& os, ModNum n) {
    return os << n.x;
  }

  friend std::istream& operator>>(std::istream& is, ModNum& n) {
    T v;
    is >> v;
    n = ModNum(v);
    return is;
  }

 private:
  T x;
};
