#include <algorithm>
#include <cstddef>
#include <cstdlib>
#include <limits>
#include <type_traits>
#include <vector>

namespace segtree {

struct Sum {
  template <typename T>
  T operator()(const T& a, const T& b) const noexcept {
    return a + b;
  }

  template <typename T>
  T identity() const noexcept {
    return 0;
  }
};

struct Min {
  template <typename T>
  T operator()(const T& a, const T& b) const noexcept {
    return std::min(a, b);
  }

  template <typename T>
  T identity() const noexcept {
    return std::numeric_limits<T>::max();
  }
};

struct Max {
  template <typename T>
  T operator()(const T& a, const T& b) const noexcept {
    return std::max(a, b);
  }

  template <typename T>
  T identity() const noexcept {
    return std::numeric_limits<T>::min();
  }
};

};  // namespace segtree

// Eager SegmentTree.
template <typename T = long long, typename BinaryOp = segtree::Sum>
class ESegmentTree {
 public:
  ESegmentTree(int sz)
      : n_(sz), op_(), st_(4 * n_, op_.template identity<T>()) {}

  ESegmentTree(const std::vector<T>& data) : ESegmentTree(data.size()) {
    build(data, 1, 0, n_ - 1);
  }

  T query(int l, int r) const { return query(1, 0, n_ - 1, l, r); }

  void update(int pos, int val) { update(1, 0, n_ - 1, pos, val); }

  T kthElement(T k) const { return kthElement(1, 0, n_ - 1, k); }

 private:
  const int n_{};
  const BinaryOp op_{};

  std::vector<T> st_{};

  static constexpr int left(int x) { return x << 1; }

  static constexpr int right(int x) { return (x << 1) + 1; }

  void build(const std::vector<T>& data, int idx, int L, int R) {
    if (L == R) {
      st_[idx] = data[L];
      return;
    }

    int mid = (L + R) / 2;

    build(data, left(idx), L, mid);
    build(data, right(idx), mid + 1, R);

    st_[idx] = op_(st_[left(idx)], st_[right(idx)]);
  }

  T query(int idx, int L, int R, int l, int r) const {
    if (l > r) {
      return op_.template identity<T>();
    }

    // if the backing array's index is contained within the queried range.
    if (l <= L && R <= r) {
      return st_[idx];
    }

    int mid = (L + R) / 2;
    return op_(query(left(idx), L, mid, l, std::min(r, mid)),
               query(right(idx), mid + 1, R, std::max(l, mid + 1), r));
  }

  void update(int idx, int L, int R, int pos, T val) {
    if (L == R) {
      st_[idx] = val;
      return;
    }

    int mid = (L + R) / 2;
    if (pos <= mid) {
      update(left(idx), L, mid, pos, val);
    } else {
      update(right(idx), mid + 1, R, pos, val);
    }
    st_[idx] = op_(st_[left(idx)], st_[right(idx)]);
  }

  T kthElement(int idx, int L, int R, T k) const {
    static_assert(std::is_same_v<BinaryOp, segtree::Sum>,
                  "kthElement requires Sum operation");

    if (k > st_[idx]) {
      return -1;
    }

    if (L == R) {
      return L;
    }

    int mid = (L + R) / 2;
    if (st_[left(idx)] >= k) {
      return kthElement(left(idx), L, mid, k);
    } else {
      return kthElement(right(idx), mid + 1, R, k - st_[left(idx)]);
    }
  }
};

template <typename T = long long, typename BinaryOp = segtree::Sum>
class SegmentTree {
 public:
  SegmentTree(int sz)
      : n_(sz),
        op_(),
        st_(4 * n_, op_.template identity<T>()),
        lazy_(4 * n_, 0),
        hasUpdates_(4 * n_, false) {}

  SegmentTree(const std::vector<T>& data) : SegmentTree(data.size()) {
    build(data, 1, 0, n_ - 1);
  }

  T query(int l, int r) { return query(1, 0, n_ - 1, l, r); }

  void update(int l, int r, T val) { update(1, 0, n_ - 1, l, r, val); }

  // find the k-th smallest element in the range [l, r]
  T kthElement(int k) { return kthElement(1, 0, n_ - 1, k); }

 private:
  const int n_;

  BinaryOp op_{};

  std::vector<T> st_;

  std::vector<T> lazy_;

  std::vector<bool> hasUpdates_;

  static int left(int i) { return i << 1; }
  static int right(int i) { return (i << 1) + 1; }

  void build(const std::vector<T>& data, int idx, int l, int r) {
    if (l == r) {
      st_[idx] = data[l];
    } else {
      int mid = (l + r) / 2;

      build(data, left(idx), l, mid);
      build(data, right(idx), mid + 1, r);

      st_[idx] = op_(st_[left(idx)], st_[right(idx)]);
    }
  }

  void propagate(int idx, int l, int r) {
    if (!hasUpdates_[idx]) {
      return;
    }
    hasUpdates_[idx] = false;

    if constexpr (std::is_same_v<BinaryOp, segtree::Sum>) {
      // for sum, there is a need to multiply by the size of the segment.
      st_[idx] = (lazy_[idx] * (r - l + 1));
    } else if constexpr (std::is_same_v<BinaryOp, segtree::Min> ||
                         std::is_same_v<BinaryOp, segtree::Max>) {
      // for min/max, the value is simply propagated, reflecting a replace.
      st_[idx] = lazy_[idx];
    }

    // non-leaf, propagate downwards.
    if (l != r) {
      lazy_[left(idx)] = lazy_[idx];
      lazy_[right(idx)] = lazy_[idx];

      hasUpdates_[left(idx)] = true;
      hasUpdates_[right(idx)] = true;
    }
    lazy_[idx] = 0;  // reset. Not necessary.
  };

  T query(int idx, int tL, int tR, int l, int r) {
    if (l > r) {
      return op_.template identity<T>();
    }

    propagate(idx, tL, tR);

    if (l <= tL && r >= tR) {
      return st_[idx];
    }

    int mid = (tL + tR) / 2;
    return op_(query(left(idx), tL, mid, l, std::min(r, mid)),
               query(right(idx), mid + 1, tR, std::max(l, mid + 1), r));
  }

  void update(int idx, int tL, int tR, int l, int r, T val) {
    propagate(idx, tL, tR);

    if (l > tR || r < tL) {
      return;
    }

    if (l <= tL && r >= tR) {
      lazy_[idx] = val;
      hasUpdates_[idx] = true;
      propagate(idx, tL, tR);
      return;
    }

    int mid = (tL + tR) / 2;
    update(left(idx), tL, mid, l, r, val);
    update(right(idx), mid + 1, tR, l, r, val);

    st_[idx] = op_(st_[left(idx)], st_[right(idx)]);
  }

  T kthElement(int idx, int tL, int tR, int k) {
    propagate(idx, tL, tR);

    if constexpr (std::is_same_v<BinaryOp, segtree::Sum>) {
      if (k > st_[idx]) {
        return -1;
      }

      if (tL == tR) {
        return tL;
      }

      int mid = (tL + tR) / 2;
      if (st_[left(idx)] >= k) {
        return kthElement(left(idx), tL, mid, k);
      } else {
        return kthElement(right(idx), mid + 1, tR, k - st_[left(idx)]);
      }
    } else {
      // For non-Sum operations, we would need different logic
      // For now, return -1 to indicate unsupported operation
      return -1;
    }
  }
};
