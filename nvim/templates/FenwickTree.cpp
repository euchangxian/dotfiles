#include <cassert>
#include <iostream>
#include <vector>

template <typename T = int>
class PURQ {
 public:
  PURQ(int m) : n_(m), ft_(m + 1, 0) {}

  PURQ(const std::vector<T>& raw) : n_(raw.size()), ft_(n_ + 1, 0) {
    for (int i = 1; i <= n_; ++i) {
      ft_[i] += raw[i - 1];

      int parent = i + (i & -i);
      if (parent <= n_) {
        ft_[parent] += ft_[i];
      }
    }
  }

  // {l, r} are 1-indexed.
  T rangeQuery(int i) const {
    // Prefix sum overload.
    return query(i) - query(0);
  }

  // {l, r} are 1-indexed.
  T rangeQuery(int l, int r) const { return query(r) - query(l - 1); }

  // i is 1-indexed.
  void pointUpdate(int i, T diff) {
    // Add `diff` to point i.
    while (i <= n_) {
      ft_[i] += diff;
      i += i & -i;
    }
  }

  // Fenwick Trees are able to answer the query: find index i (of the
  // underlying array) such that the cumulative sum up to i is >= k.
  // As such, by preprocessing the original array into a frequency/presence
  // array, Fenwick Trees can be used to answer: find the kth smallest element,
  // i.e., Order Statistics.
  //
  // E.g.,
  // Original array: [20, 50, 10]
  // We preprocess this into a presence array:
  // [0,0,...,1,...,1,...,1,...]
  //          ^     ^     ^
  //          10    20    50

  // When we ask for 2nd smallest element:
  // "Find first index where cumsum >= 2"
  // = "Find index of second 1 in presence array"
  // = "Find second smallest original value"
  // Returns the 1-indexed Index.
  int kthElement(T k) const {
    // int left = 1;
    // int right = n_;
    // while (left < right) {
    //   int mid = left + (right - left) / 2;
    //
    //   // prefix sum
    //   if (rangeQuery(mid) < k) {
    //     left = mid + 1;
    //   } else {
    //     right = mid;
    //   }
    // }
    //
    // return left;

    // Faster, O(logn) binary lifting.
    if (k <= 0 || k > rangeQuery(n_ + 1)) {
      return -1;
    }

    int idx = 0;
    int step = 1 << (31 - __builtin_clz(n_));

    T sum = 0;
    while (step > 0) {
      int next = idx + step;

      if (next <= n_ && sum + ft_[next] < k) {
        idx = next;
        sum += ft_[next];
      }
      step >>= 1;
    }
    return idx + 1;
  }

 private:
  // i is 1-indexed, as this can only be invoked internally.
  T query(int i) const {
    T sum = 0;
    while (i > 0) {
      sum += ft_[i];
      i -= i & -i;
    }

    return sum;
  }

  std::size_t n_{};
  std::vector<T> ft_;
};

template <typename T = int>
class RUPQ {
 public:
  RUPQ(int m) : purq(m) {}

  RUPQ(const std::vector<T>& raw) : purq(raw) {}

  void rangeUpdate(int l, int r, T diff) {
    // l, r is 1-indexed.
    purq.pointUpdate(l, diff);       // +diff to every point [l..n-1]
    purq.pointUpdate(r + 1, -diff);  // -diff to every point [r+1..n-1]
  }

  T pointQuery(int i) const {
    // i is 1-indexed.
    return purq.rangeQuery(i);
  }

 private:
  PURQ<T> purq;
};

template <typename T = int>
class RURQ {
 public:
  RURQ(int m) : rupq(m), purq(m) {}

  RURQ(const std::vector<T>& raw) : rupq(raw), purq(raw) {}

  // 1-indexed
  void rangeUpdate(int l, int r, T diff) {
    rupq.rangeUpdate(l, r, diff);

    purq.pointUpdate(l, diff * (l - 1));
    purq.pointUpdate(r + 1, -diff * r);
  }

  // 1-indexed
  T rangeQuery(int i) const {
    return rupq.pointQuery(i) * i - purq.rangeQuery(i);
  }

  // l, r are 1-indexed
  T rangeQuery(int l, int r) const { return rangeQuery(r) - rangeQuery(l - 1); }

 private:
  RUPQ<T> rupq;
  PURQ<T> purq;
};

int main() {
  std::vector<int> data{0, 1, 0, 1, 2, 3, 2, 1, 1, 0};

  PURQ<int> purq{data};
  assert(purq.rangeQuery(2, 6) == 7);
  assert(purq.kthElement(7) == 6);

  purq.pointUpdate(6, 1);
  assert(purq.rangeQuery(1, 10) == 12);

  RUPQ<int> rupq(10);
  RURQ<int> rurq(10);
  rupq.rangeUpdate(2, 9, 7);
  rurq.rangeUpdate(2, 9, 7);
  rupq.rangeUpdate(6, 7, 3);
  rurq.rangeUpdate(6, 7, 3);
  // idx = 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9
  // val = 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0 | 0
  // rangeUpdate(1, 8, 7)
  // val = 0 | 7 | 7 | 7 | 7 | 7 | 7 | 7 | 7 | 0
  //
  // rangeUpdate(5, 6, 3)
  // val = 0 | 7 | 7 | 7 | 7 | 10 | 10 | 7 | 7 | 0
  int pointSum = 0;
  for (int i = 1; i <= 10; ++i) {
    pointSum += rupq.pointQuery(i);
  }
  assert(rupq.pointQuery(6) == 10);

  assert(pointSum == 62);
  assert(rurq.rangeQuery(1, 10) == 62);
  assert(pointSum == rurq.rangeQuery(1, 10));
  assert(rurq.rangeQuery(6, 7) == 20);
}
