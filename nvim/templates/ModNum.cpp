#include <cstddef>
#include <cstdlib>
#include <iostream>
#include <istream>
#include <type_traits>

template <typename T = int, int MOD = 1'000'000'007>
class ModNum {
 public:
  ModNum() : x(0) {}

  template <typename U>
  ModNum(U v) {
    if constexpr (std::is_same_v<T, int>) {
      x = static_cast<T>(static_cast<long long>(v) % MOD);
    } else {
      x = static_cast<T>(v % MOD);
    }

    if (x < 0) {
      x += MOD;
    }
  }

  T get() const { return x; }
  operator int() const { return static_cast<int>(x); }
  operator long long() const { return static_cast<long long>(x); }

  // ModNum + ModNum
  ModNum<T, MOD> operator+(const ModNum<T, MOD>& other) const {
    if constexpr (std::is_same_v<T, int>) {
      return ModNum<T, MOD>(
          static_cast<T>((static_cast<long long>(x) + other.x) % MOD));
    }
    return ModNum<T, MOD>(static_cast<T>((x + other.x) % MOD));
  }

  // ModNum + arithmetic type
  template <typename U, typename = std::enable_if_t<std::is_arithmetic_v<U>>>
  ModNum<T, MOD> operator+(U other) const {
    if constexpr (std::is_same_v<T, int>) {
      return ModNum<T, MOD>(
          static_cast<T>((static_cast<long long>(x) + other) % MOD));
    }
    return ModNum<T, MOD>(static_cast<T>((x + other) % MOD));
  }

  ModNum<T, MOD>& operator+=(const ModNum& other) {
    if constexpr (std::is_same_v<T, int>) {
      x = static_cast<T>((static_cast<long long>(x) + other.x) % MOD);
    } else {
      x = static_cast<T>((x + other.x) % MOD);
    }
    return *this;
  }

  template <typename U, typename = std::enable_if_t<std::is_arithmetic_v<U>>>
  ModNum<T, MOD>& operator+=(U other) {
    if constexpr (std::is_same_v<T, int>) {
      x = static_cast<T>((static_cast<long long>(x) + other) % MOD);
    } else {
      x = static_cast<T>((x + other) % MOD);
    }
    return *this;
  }

  // WARNING: shifts the number into the positive range. Not remainder.
  ModNum<T, MOD> operator-(const ModNum<T, MOD>& other) const {
    if constexpr (std::is_same_v<T, int>) {
      return ModNum<T, MOD>(
          static_cast<T>((static_cast<long long>(x) - other.x + MOD) % MOD));
    }
    return ModNum<T, MOD>(static_cast<T>((x - other.x + MOD) % MOD));
  }

  template <typename U, typename = std::enable_if_t<std::is_arithmetic_v<U>>>
  ModNum<T, MOD> operator-(U other) const {
    if constexpr (std::is_same_v<T, int>) {
      return ModNum<T, MOD>(
          static_cast<T>((static_cast<long long>(x) - other + MOD) % MOD));
    }
    return ModNum<T, MOD>(static_cast<T>((x - other + MOD) % MOD));
  }

  ModNum<T, MOD>& operator-=(const ModNum<T, MOD>& other) {
    if constexpr (std::is_same_v<T, int>) {
      x = static_cast<T>((static_cast<long long>(x) - other.x + MOD) % MOD);
    } else {
      x = static_cast<T>((x - other.x + MOD) % MOD);
    }
    return *this;
  }

  template <typename U, typename = std::enable_if_t<std::is_arithmetic_v<U>>>
  ModNum<T, MOD>& operator-=(U other) {
    if constexpr (std::is_same_v<T, int>) {
      x = static_cast<T>((static_cast<long long>(x) - other + MOD) % MOD);
    } else {
      x = static_cast<T>((x - other + MOD) % MOD);
    }
    return *this;
  }

  ModNum<T, MOD> operator*(const ModNum<T, MOD>& other) const {
    if constexpr (std::is_same_v<T, int>) {
      return ModNum<T, MOD>(
          static_cast<T>((static_cast<long long>(x) * other.x) % MOD));
    }
    return ModNum<T, MOD>(static_cast<T>((x * other.x) % MOD));
  }

  template <typename U, typename = std::enable_if_t<std::is_arithmetic_v<U>>>
  ModNum<T, MOD> operator*(U other) const {
    if constexpr (std::is_same_v<T, int>) {
      return ModNum<T, MOD>(
          static_cast<T>((static_cast<long long>(x) * other) % MOD));
    }
    return ModNum<T, MOD>(static_cast<T>((x * other) % MOD));
  }

  ModNum<T, MOD>& operator*=(const ModNum<T, MOD>& other) {
    if constexpr (std::is_same_v<T, int>) {
      x = static_cast<T>((static_cast<long long>(x) * other.x) % MOD);
    } else {
      x = static_cast<T>((x * other.x) % MOD);
    }
    return *this;
  }

  template <typename U, typename = std::enable_if_t<std::is_arithmetic_v<U>>>
  ModNum<T, MOD>& operator*=(U other) {
    if constexpr (std::is_same_v<T, int>) {
      x = static_cast<T>((static_cast<long long>(x) * other) % MOD);
    } else {
      x = static_cast<T>((x * other) % MOD);
    }
    return *this;
  }

  // Division (using Fermat's little theorem for modular inverse)
  ModNum<T, MOD> inverse() const { return pow(MOD - 2); }

  ModNum<T, MOD> operator/(const ModNum<T, MOD>& other) const {
    return *this * other.inverse();
  }

  template <typename U, typename = std::enable_if_t<std::is_arithmetic_v<U>>>
  ModNum<T, MOD> operator/(U other) const {
    return *this / ModNum<T, MOD>(other);
  }

  ModNum<T, MOD>& operator/=(const ModNum<T, MOD>& other) {
    return *this *= other.inverse();
  }

  template <typename U, typename = std::enable_if_t<std::is_arithmetic_v<U>>>
  ModNum<T, MOD>& operator/=(U other) {
    return *this /= ModNum<T, MOD>(other);
  }

  // Power (using binary exponentiation)
  ModNum<T, MOD> pow(T exponent) const {
    ModNum<T, MOD> result(1);
    ModNum<T, MOD> base(x);

    while (exponent > 0) {
      if (exponent & 1) {
        result *= base;
      }
      base *= base;
      exponent >>= 1;
    }

    return result;
  }

  bool operator==(const ModNum<T, MOD>& other) const { return x == other.x; }
  bool operator!=(const ModNum<T, MOD>& other) const { return x != other.x; }

  friend std::ostream& operator<<(std::ostream& os, const ModNum<T, MOD>& num) {
    return os << num.x;
  }

  friend std::istream& operator>>(std::istream& is, ModNum<T, MOD>& num) {
    T v;
    is >> v;
    num = ModNum<T, MOD>(v);
    return is;
  }

  // Non-member friend operators for arithmetic + ModNun
  template <typename U>
  friend typename std::enable_if_t<std::is_arithmetic_v<U>, ModNum<T, MOD>>
  operator+(U a, const ModNum<T, MOD>& b) {
    return ModNum<T, MOD>(a) + b;
  }

  template <typename U>
  friend typename std::enable_if_t<std::is_arithmetic_v<U>, ModNum<T, MOD>>
  operator-(U a, const ModNum<T, MOD>& b) {
    return ModNum<T, MOD>(a) - b;
  }

  template <typename U>
  friend typename std::enable_if_t<std::is_arithmetic_v<U>, ModNum<T, MOD>>
  operator*(U a, const ModNum<T, MOD>& b) {
    return ModNum<T, MOD>(a) * b;
  }

  template <typename U>
  friend typename std::enable_if_t<std::is_arithmetic_v<U>, ModNum<T, MOD>>
  operator/(U a, const ModNum<T, MOD>& b) {
    return ModNum<T, MOD>(a) / b;
  }

 private:
  T x;
};
