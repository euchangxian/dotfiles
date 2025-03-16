/**
 * Matrix operations for competitive programming
 * Usage:
 *   Matrix<int, 3> A = {{{1,2,3}, {4,5,6}, {7,8,9}}};
 *   array<int, 3> vec = {1,2,3};
 *   vec = (A^n) * vec;
 */

#include <array>
#include <cassert>

template <typename T, int N>
class Matrix {
 public:
  std::array<std::array<T, N>, N> data{};

  Matrix() = default;

  Matrix(const std::array<std::array<T, N>, N>& initial) : data(initial) {}

  std::array<T, N>& operator[](int index) { return data[index]; }

  const std::array<T, N>& operator[](int index) const { return data[index]; }

  Matrix operator*(const Matrix& other) const {
    Matrix result;
    for (int i = 0; i < N; ++i) {
      for (int j = 0; j < N; ++j) {
        result.data[i][j] = 0;
        for (int k = 0; k < N; ++k) {
          result.data[i][j] += data[i][k] * other.data[k][j];
        }
      }
    }
    return result;
  }

  Matrix operator*=(const Matrix& other) {
    *this = *this * other;
    return *this;
  }

  std::array<T, N> operator*(const std::array<T, N>& vec) const {
    std::array<T, N> result{};
    for (int i = 0; i < N; ++i) {
      for (int j = 0; j < N; ++j) {
        result[i] += data[i][j] * vec[j];
      }
    }
    return result;
  }

  Matrix operator^(long long exponent) const {
    assert(exponent >= 0);
    Matrix result;
    // Initialize result as identity matrix
    for (int i = 0; i < N; ++i) {
      result.data[i][i] = 1;
    }

    Matrix base(*this);
    while (exponent > 0) {
      if (exponent & 1) {
        result = result * base;
      }
      base = base * base;
      exponent >>= 1;
    }
    return result;
  }

  Matrix& operator^=(long long exponent) {
    *this = *this ^ exponent;
    return *this;
  }

  static Matrix identity() {
    Matrix result;
    for (int i = 0; i < N; ++i) {
      result.data[i][i] = 1;
    }
    return result;
  }
};

// Utility function for calculating Fibonacci numbers using matrix
// exponentiation [ [1, 1], [1, 0] ]^n = [ [F(n+1), F(n)], [F(n), F(n-1)] ]
// More of an example.
template <typename T>
T fibonacci(long long n) {
  if (n <= 0) {
    return 0;
  }
  if (n == 1) {
    return 1;
  }

  Matrix<T, 2> base = {{{1, 1}, {1, 0}}};
  Matrix<T, 2> result = base ^ (n - 1);
  return result.data[0][0];
}
