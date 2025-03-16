#include <algorithm>
#include <cstddef>
#include <cstdlib>
#include <queue>
#include <tuple>
#include <unordered_map>
#include <vector>

using i64 = long long;
constexpr i64 INF = 1e18;
class MaxFlow {
 public:
  MaxFlow(int initialV) : V(initialV) {
    EL.clear();
    AL.assign(V, std::vector<int>());
    EM.assign(V, std::unordered_map<int, int>());
  }

  void addEdge(int u, int v, i64 w, bool directed = true) {
    if (u == v) {
      return;
    }
    EL.emplace_back(v, w, 0);
    AL[u].push_back(EL.size() - 1);
    EL.emplace_back(u, directed ? 0 : w, 0);
    AL[v].push_back(EL.size() - 1);
    EM[u][v] = static_cast<int>(EL.size()) - 2;
  }

  i64 getEdge(int u, int v) {
    if (EM[u].find(v) == EM[u].end()) {
      return -1;
    } else {
      return std::get<2>(EL[EM[u][v]]);
    }
  }

  i64 dinic(int s, int t) {
    i64 mf = 0;
    while (BFS(s, t)) {
      last.assign(V, 0);
      while (i64 f = DFS(s, t)) {
        mf += f;
      }
    }
    return mf;
  }

  std::vector<std::vector<int>> minCut(int s) {
    std::vector<bool> visited(V, false);
    std::queue<int> q;
    q.push(s);
    visited[s] = true;

    while (!q.empty()) {
      int u = q.front();
      q.pop();
      for (int idx : AL[u]) {
        auto [v, cap, flow] = EL[idx];
        if (!visited[v] && cap - flow > 0) {
          visited[v] = true;
          q.push(v);
        }
      }
    }

    std::vector<std::vector<int>> minCut;
    for (int u = 0; u < V; ++u) {
      if (visited[u]) {
        for (int idx : AL[u]) {
          auto [v, cap, flow] = EL[idx];
          if (!visited[v] && cap > 0) {
            minCut.emplace_back(u, v);
          }
        }
      }
    }
    return minCut;
  }

 private:
  int V;
  std::vector<std::unordered_map<int, int>> EM;
  std::vector<std::tuple<int, i64, i64>> EL;
  std::vector<std::vector<int>> AL;
  std::vector<int> d;
  std::vector<int> last;

  bool BFS(int s, int t) {
    d.assign(V, -1);
    d[s] = 0;
    std::queue<int> q({s});
    while (!q.empty()) {
      int u = q.front();
      q.pop();
      if (u == t) {
        break;
      }
      for (auto& idx : AL[u]) {
        auto& [v, cap, flow] = EL[idx];
        if ((cap - flow > 0) && (d[v] == -1)) {
          d[v] = d[u] + 1, q.push(v);
        }
      }
    }
    return d[t] != -1;
  }

  i64 DFS(int u, int t, i64 f = INF) {
    if ((u == t) || (f == 0)) {
      return f;
    }
    for (int& i = last[u]; i < static_cast<int>(AL[u].size());
         ++i) {  // from last edge
      auto& [v, cap, flow] = EL[AL[u][i]];
      if (d[v] != d[u] + 1) {
        continue;  // not part of layer graph
      }
      if (i64 pushed = DFS(v, t, std::min(f, cap - flow))) {
        flow += pushed;
        auto& rflow = std::get<2>(EL[AL[u][i] ^ 1]);
        rflow -= pushed;
        return pushed;
      }
    }
    return 0;
  }
};
