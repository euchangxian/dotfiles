#include <algorithm>
#include <queue>
#include <utility>
#include <vector>

using i64 = long long;
constexpr int MOD = 1'000'000'007;

const i64 INF = 1e18;  // INF = 1e18, not 2^63-1 to avoid overflow
class MinCostMaxFlow {
 private:
  int V;
  i64 totalCost;
  std::vector<std::tuple<int, i64, i64, i64>> EL;
  std::vector<std::vector<int>> AL;
  std::vector<i64> d;
  std::vector<int> last;
  std::vector<int> vis;

  bool SPFA(int s, int t) {  // SPFA to find augmenting path in residual graph
    d.assign(V, INF);
    d[s] = 0;
    vis[s] = 1;
    std::queue<int> q({s});
    while (!q.empty()) {
      int u = q.front();
      q.pop();
      vis[u] = 0;
      for (auto& idx : AL[u]) {                // explore neighbors of u
        auto& [v, cap, flow, cost] = EL[idx];  // stored in EL[idx]
        if ((cap - flow > 0) &&
            (d[v] > d[u] + cost)) {  // positive residual edge
          d[v] = d[u] + cost;
          if (!vis[v]) {
            q.push(v), vis[v] = 1;
          }
        }
      }
    }
    return d[t] != INF;  // has an augmenting path
  }

  i64 DFS(int u, int t, i64 f = INF) {  // traverse from s->t
    if ((u == t) || (f == 0)) {
      return f;
    }
    vis[u] = 1;
    for (int& i = last[u]; i < (int)AL[u].size(); ++i) {  // from last edge
      auto& [v, cap, flow, cost] = EL[AL[u][i]];
      if (!vis[v] && d[v] == d[u] + cost) {  // in current layer graph
        if (i64 pushed = DFS(v, t, std::min(f, cap - flow))) {
          totalCost += pushed * cost;
          flow += pushed;
          auto& [rv, rcap, rflow, rcost] = EL[AL[u][i] ^ 1];  // back edge
          rflow -= pushed;
          vis[u] = 0;
          return pushed;
        }
      }
    }
    vis[u] = 0;
    return 0;
  }

 public:
  MinCostMaxFlow(int initialV) : V(initialV), totalCost(0) {
    EL.clear();
    AL.assign(V, std::vector<int>());
    vis.assign(V, 0);
  }

  // if you are adding a bidirectional edge u<->v with weight w into your
  // flow graph, set directed = false (default value is directed = true)
  void add_edge(int u, int v, i64 w, i64 c, bool directed = true) {
    if (u == v) {
      return;  // safeguard: no self loop
    }
    EL.emplace_back(v, w, 0, c);     // u->v, cap w, flow 0, cost c
    AL[u].push_back(EL.size() - 1);  // remember this index
    EL.emplace_back(u, 0, 0, -c);    // back edge
    AL[v].push_back(EL.size() - 1);  // remember this index
    if (!directed) {
      add_edge(v, u, w, c);  // add again in reverse
    }
  }

  std::pair<i64, i64> mcmf(int s, int t) {
    i64 mf = 0;                    // mf stands for max_flow
    while (SPFA(s, t)) {           // an O(V^2*E) algorithm
      last.assign(V, 0);           // important speedup
      while (i64 f = DFS(s, t)) {  // exhaust blocking flow
        mf += f;
      }
    }
    return {mf, totalCost};
  }
};
