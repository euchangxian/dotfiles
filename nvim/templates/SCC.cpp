#include <algorithm>
#include <cstddef>
#include <cstdlib>
#include <stack>
#include <vector>

class SCC {
 public:
  SCC(int vertices) : computed(false), V(vertices), numSCCs(0), time(0) {
    adj.resize(V);
    componentOf.assign(V, -1);
  }

  void addEdge(int v, int w) { adj[v].push_back(w); }

  void tarjanSCC() {
    if (computed) {
      return;  // avoid recomputing
    }

    time = 0;
    numSCCs = 0;
    componentOf.assign(V, -1);

    std::vector<int> discovery(V, -1);
    std::vector<int> lowest(V, -1);
    std::stack<int> st;

    // Process all vertices
    for (int i = 0; i < V; i++) {
      if (discovery[i] == -1) {
        tarjanSCC(i, discovery, lowest, st);
      }
    }

    computed = true;
  }

  int getNumSCCs() {
    if (!computed) {
      tarjanSCC();
    }
    return numSCCs;
  }

  const std::vector<int>& getComponentMap() {
    if (!computed) {
      tarjanSCC();
    }
    return componentOf;
  }

  // Get all vertices in a specific component
  std::vector<int> getComponent(int compId) {
    if (!computed) {
      tarjanSCC();
    }

    std::vector<int> result;
    for (int i = 0; i < V; i++) {
      if (componentOf[i] == compId) {
        result.push_back(i);
      }
    }
    return result;
  }

  // Get all SCCs as lists of vertices
  std::vector<std::vector<int>> getAllSCCs() {
    if (!computed) {
      tarjanSCC();
    }

    std::vector<std::vector<int>> result(numSCCs);
    for (int i = 0; i < V; i++) {
      result[componentOf[i]].push_back(i);
    }
    return result;
  }

 private:
  bool computed;
  int V;     // Number of vertices
  int time;  // For Tarjan's algorithm
  int numSCCs;

  std::vector<std::vector<int>> adj;  // Adjacency list
  std::vector<int> componentOf;       // Maps each vertex to its component ID

  int tarjanSCC(int u,
                std::vector<int>& discovery,
                std::vector<int>& lowest,
                std::stack<int>& st) {
    discovery[u] = lowest[u] = ++time;
    st.push(u);

    for (int v : adj[u]) {
      // Only consider vertices not yet assigned to a component
      if (componentOf[v] == -1) {
        // If not discovered, recursively visit
        if (discovery[v] == -1) {
          tarjanSCC(v, discovery, lowest, st);
          lowest[u] = std::min(lowest[u], lowest[v]);
        }
        // Back edge to a vertex in current SCC
        else {
          lowest[u] = std::min(lowest[u], discovery[v]);
        }
      }
    }

    // If u is root of an SCC
    if (lowest[u] == discovery[u]) {
      // Process all vertices in the current SCC
      int v;
      do {
        v = st.top();
        st.pop();
        componentOf[v] = numSCCs;
      } while (v != u);

      numSCCs++;
    }

    return lowest[u];
  }
};
