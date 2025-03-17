#include <iostream>
#include <istream>
#include <type_traits>

template <typename T = int, int MOD = 1'000'000'007>
class ModNum {
  template <typename U = T>
  using safe_multiply_t =
      std::conditional_t<std::is_same_v<U, int>, long long, U>;

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

  constexpr T get() const noexcept { return x; }
  constexpr operator int() const noexcept { return static_cast<int>(x); }
  constexpr operator long long() const noexcept {
    return static_cast<long long>(x);
  }

  // ModNum + ModNum
  ModNum<T, MOD> operator+(const ModNum<T, MOD>& other) const {
    ModNum<T, MOD> result(*this);
    result += other;
    return result;
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
    x += other.x;
    if (x >= MOD) {
      x -= MOD;
    }
    return *this;
  }

  template <typename U, typename = std::enable_if_t<std::is_arithmetic_v<U>>>
  ModNum<T, MOD>& operator+=(U other) {
    ModNum<T, MOD> temp(other);
    return *this += temp;
  }

  // WARNING: shifts the number into the positive range. Not remainder.
  ModNum<T, MOD> operator-(const ModNum<T, MOD>& other) const {
    ModNum<T, MOD> result(*this);
    result -= other;
    return result;
  }

  template <typename U, typename = std::enable_if_t<std::is_arithmetic_v<U>>>
  ModNum<T, MOD> operator-(U other) const {
    ModNum<T, MOD> temp(other);
    return *this -= temp;
  }

  ModNum<T, MOD>& operator-=(const ModNum<T, MOD>& other) {
    if (x < other.x) {
      x += MOD;
    }
    x -= other.x;
    return *this;
  }

  template <typename U, typename = std::enable_if_t<std::is_arithmetic_v<U>>>
  ModNum<T, MOD>& operator-=(U other) {
    ModNum<T, MOD> temp(other);
    return *this -= temp;
  }

  ModNum<T, MOD> operator*(const ModNum<T, MOD>& other) const {
    ModNum<T, MOD> result(*this);
    result *= other;
    return result;
  }

  template <typename U, typename = std::enable_if_t<std::is_arithmetic_v<U>>>
  ModNum<T, MOD> operator*(U other) const {
    ModNum<T, MOD> result(*this);
    result *= other;
    return result;
  }

  ModNum<T, MOD>& operator*=(const ModNum<T, MOD>& other) {
    x = static_cast<T>((static_cast<safe_multiply_t<T>>(x) * other.x) % MOD);
    return *this;
  }

  template <typename U, typename = std::enable_if_t<std::is_arithmetic_v<U>>>
  ModNum<T, MOD>& operator*=(U other) {
    ModNum<T, MOD> temp(other);
    return *this *= temp;
  }

  // Division (using Fermat's little theorem for modular inverse)
  ModNum<T, MOD> inverse() const { return modPow(MOD - 2); }

  ModNum<T, MOD> operator/(const ModNum<T, MOD>& other) const {
    ModNum<T, MOD> result(*this);
    result /= other;
    return result;
  }

  template <typename U, typename = std::enable_if_t<std::is_arithmetic_v<U>>>
  ModNum<T, MOD> operator/(U other) const {
    ModNum<T, MOD> result(*this);
    result /= other;
    return result;
  }

  ModNum<T, MOD>& operator/=(const ModNum<T, MOD>& other) {
    return *this *= other.inverse();
  }

  template <typename U, typename = std::enable_if_t<std::is_arithmetic_v<U>>>
  ModNum<T, MOD>& operator/=(U other) {
    return *this /= ModNum<T, MOD>(other);
  }

  // Power (using binary exponentiation)
  ModNum<T, MOD> modPow(T exponent) const {
    ModNum<T, MOD> result(1);
    ModNum<T, MOD> base(*this);

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
