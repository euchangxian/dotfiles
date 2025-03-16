#include <algorithm>
#include <bitset>
#include <vector>

using i64 = long long;
constexpr int MAX_VERTICES = 200;

class MaxClique {
 public:
  MaxClique(std::vector<std::bitset<MAX_VERTICES>>& conn)
      : e(conn), C(conn.size() + 1), S(C.size()), old(S) {
    for (int i = 0; i < (int)conn.size(); ++i) {
      V.push_back({i});
    }
  }

  std::vector<int> maxClique() {
    initializeVertices(V);
    expand(V);
    return qmax;
  }

 private:
  struct Vertex {
    int i;
    int d = 0;
  };

  // Graph stored as adjacency matrix in bitsets
  std::vector<std::bitset<MAX_VERTICES>> e;
  std::vector<Vertex> V;
  std::vector<std::vector<int>> C;
  std::vector<int> qmax;  // Maximum clique found so far
  std::vector<int> q;     // Current clique being built
  std::vector<int> S;     // Statistics for pruning
  std::vector<int> old;
  double limit = 0.025;
  double pk = 0;

  void initializeVertices(std::vector<Vertex>& r) {
    // Calculate degrees
    for (auto& v : r) {
      v.d = 0;
    }
    for (auto& v : r) {
      for (auto& j : r) {
        v.d += e[v.i][j.i];
      }
    }

    // Sort by degree (highest degree first)
    std::sort(r.begin(), r.end(), [](auto a, auto b) { return a.d > b.d; });

    // Adjust degree for coloring bound
    int mxD = r[0].d;
    for (int i = 0; i < (int)r.size(); ++i) {
      r[i].d = std::min(i, mxD) + 1;
    }
  }

  void expand(std::vector<Vertex>& R, int lev = 1) {
    S[lev] += S[lev - 1] - old[lev];
    old[lev] = S[lev - 1];

    while (!R.empty()) {
      // Prune if the current clique plus all remaining vertices can't beat the
      // best
      if (q.size() + R.back().d <= qmax.size()) {
        return;
      }

      // Add vertex to current clique
      q.push_back(R.back().i);

      // Find neighbors of the selected vertex
      std::vector<Vertex> T;
      for (auto& v : R) {
        if (e[R.back().i][v.i]) {
          T.push_back({v.i});
        }
      }

      if (!T.empty()) {
        // Dynamic reordering heuristic
        if (S[lev]++ / ++pk < limit) {
          initializeVertices(T);
        }

        int j = 0;
        int mxk = 1;
        int mnk = std::max((int)qmax.size() - (int)q.size() + 1, 1);

        C[1].clear();
        C[2].clear();

        // Color-based pruning
        for (auto& v : T) {
          int k = 1;
          auto hasEdge = [&](int i) { return e[v.i][i]; };

          while (std::any_of(C[k].begin(), C[k].end(), hasEdge)) {
            k++;
          }

          if (k > mxk) {
            mxk = k;
            C[mxk + 1].clear();
          }

          if (k < mnk) {
            T[j++].i = v.i;
          }

          C[k].push_back(v.i);
        }

        if (j > 0) {
          T[j - 1].d = 0;
        }

        for (int k = mnk; k <= mxk; ++k) {
          for (int i : C[k]) {
            T[j].i = i;
            T[j++].d = k;
          }
        }

        // Recursive call
        expand(T, lev + 1);
      } else if (q.size() > qmax.size()) {
        // Update maximum clique if we found a better one
        qmax = q;
      }

      // Backtrack
      q.pop_back();
      R.pop_back();
    }
  }
};
