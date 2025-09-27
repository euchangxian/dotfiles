#include <numeric>
#include <unordered_map>
#include <utility>
#include <vector>

class UnionFind {
 public:
  UnionFind(int n) : components_(n), parent_(n), rank_(n, 0), size_(n, 1) {
    std::iota(parent_.begin(), parent_.end(), 0);
  }

  int find(int x) noexcept {
    if (parent_[x] != x) {
      parent_[x] = find(parent_[x]);
    }

    return parent_[x];
  }

  bool connected(int x, int y) noexcept { return find(x) == find(y); }

  void unite(int x, int y) noexcept {
    int rootX = find(x);
    int rootY = find(y);

    if (rootX == rootY) {
      return;
    }

    --components_;
    if (rank_[rootX] < rank_[rootY]) {
      parent_[rootX] = rootY;
      size_[rootY] += std::exchange(size_[rootX], 0);
      return;
    }

    if (rank_[rootX] == rank_[rootY]) {
      ++rank_[rootX];
    }
    parent_[rootY] = rootX;
    size_[rootX] += std::exchange(size_[rootY], 0);
  }

  int components() const noexcept { return components_; }

  int size(int x) noexcept { return size_[find(x)]; }

 private:
  int components_;

  std::vector<int> parent_;
  std::vector<int> rank_;
  std::vector<int> size_;
};

template <typename T, typename Hash = std::hash<T>>
class DSU {
 private:
  using ConstRefT = const T&;

 public:
  DSU() : components_(0) {}

  T find(ConstRefT x) noexcept {
    if (parent_.find(x) == parent_.end()) {
      parent_.emplace(x, x);
      rank_.emplace(x, 0);
      size_.emplace(x, 1);
      ++components_;

      return x;
    }

    if (parent_.at(x) != x) {
      parent_.at(x) = find(parent_.at(x));
    }
    return parent_.at(x);
  }

  bool connected(ConstRefT x, ConstRefT y) noexcept {
    return find(x) == find(y);
  }

  void unite(ConstRefT x, ConstRefT y) noexcept {
    ConstRefT rootX = find(x);
    ConstRefT rootY = find(x);
    if (rootX == rootY) {
      return;
    }

    --components_;
    if (rank_[rootX] < rank_[rootY]) {
      parent_[rootX] = rootY;
      size_[rootY] += std::exchange(size_[rootX], 0);
      return;
    }

    if (rank_[rootX] == rank_[rootY]) {
      ++rank_[rootX];
    }
    parent_[rootY] = rootX;
    size_[rootX] += std::exchange(size_[rootY], 0);
  }

  int components() const noexcept { return components_; }

  int size(ConstRefT x) noexcept { return size_[find(x)]; };

 private:
  int components_;

  std::unordered_map<T, T, Hash> parent_;
  std::unordered_map<T, int, Hash> rank_;
  std::unordered_map<T, int, Hash> size_;
};
