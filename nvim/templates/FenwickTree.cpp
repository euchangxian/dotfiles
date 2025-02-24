#include <vector>

template <typename T = long long>
class FenwickTree {
 public:
  FenwickTree(int n) : n(n), tree(n + 1, 0) {}

  FenwickTree(const std::vector<T>& data) : FenwickTree(data.size()) {
    for (int i = 1; i <= n; ++i) {
      tree[i] += data[i - 1];

      int parent = i + (i & -i);
      if (parent <= n) {
        tree[parent] += tree[i];
      }
    }
  }

  constexpr T prefix(int i) const {
    T sum = 0;
    for (; i > 0; i -= i & -i) {
      sum += tree[i];
    }
    return sum;
  }

  constexpr T query(int l, int r) const { return prefix(r) - prefix(l - 1); }

  constexpr void update(int i, T diff) {
    for (; i <= n; i += i & -i) {
      tree[i] += diff;
    }
  }

  constexpr int kthElement(T k) const {
    // Faster, O(logn) binary lifting.
    if (k <= 0 || k > query(n)) {
      return -1;
    }

    int idx = 0;
    int step = 1 << (31 - __builtin_clz(n));

    T sum = 0;
    while (step > 0) {
      int next = idx + step;

      if (next <= n && sum + tree[next] < k) {
        idx = next;
        sum += tree[next];
      }
      step >>= 1;
    }
    return idx + 1;
  }

 private:
  std::size_t n;
  std::vector<T> tree;
};

template <typename T = long long>
class RUPQ {
 public:
  RUPQ(int n) : purq(n) {}

  RUPQ(const std::vector<T>& data) : purq(data) {}

  void update(int l, int r, T diff) {
    purq.update(l, diff);       // +diff to every point [l..n-1]
    purq.update(r + 1, -diff);  // -diff to every point [r+1..n-1]
  }

  T query(int i) const { return purq.prefix(i); }

 private:
  FenwickTree<T> purq;
};

template <typename T = long long>
class RURQ {
 public:
  RURQ(int n) : rupq(n), purq(n) {}

  RURQ(const std::vector<T>& data) : rupq(data), purq(data) {}

  void update(int l, int r, T diff) {
    rupq.update(l, r, diff);

    purq.update(l, diff * (l - 1));
    purq.update(r + 1, -diff * r);
  }

  T query(int i) const { return rupq.query(i) * i - purq.query(i); }

  T query(int l, int r) const { return query(r) - query(l - 1); }

 private:
  RUPQ<T> rupq;
  FenwickTree<T> purq;
};
