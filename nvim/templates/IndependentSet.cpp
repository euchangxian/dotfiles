#include <algorithm>
#include <utility>
#include <vector>

using i64 = long long;

class IndependentSet {
 public:
  IndependentSet(std::vector<i64>& adjMat)
      : computed(false), numIS(0), maxIS(0), adjMat(std::move(adjMat)) {}

  IndependentSet(std::vector<std::vector<int>>& adj) {
    int n = adj.size();
    std::vector<i64> compacted(n);
    for (int u = 0; u < n; ++u) {
      compacted[u] = 1LL << u;
    }

    for (int u = 0; u < n; ++u) {
      for (int v = u + 1; v < n; ++v) {
        if (adj[u][v]) {
          compacted[u] |= 1LL << v;
          compacted[v] |= 1LL << u;
        }
      }
    }

    *this = IndependentSet(compacted);
  }

  std::pair<int, int> mis() {
    if (computed) {
      return {numIS, maxIS};
    }

    computed = true;
    int n = adjMat.size();
    backtrack(0, (1LL << n) - 1, 0);
    return {numIS, maxIS};
  }

 private:
  bool computed;
  int numIS;
  int maxIS;

  std::vector<i64> adjMat;

  void backtrack(int u, i64 mask, int depth) {
    if (mask == 0) {
      ++numIS;
      maxIS = std::max(maxIS, depth);
      return;
    }

    if (depth + __builtin_popcountll(mask) <= maxIS) {
      return;
    }

    i64 m = mask;
    while (m) {
      i64 twoPowV = m & -m;  // LSOne
      m -= twoPowV;

      int v = __builtin_ctzll(twoPowV);
      if (v < u) {
        continue;
      }
      backtrack(v + 1, mask & ~adjMat[v], depth + 1);
    }
  }
};
