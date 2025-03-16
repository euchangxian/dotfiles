#include <queue>
#include <unordered_set>
#include <utility>
#include <vector>

class MCBM {
 public:
  MCBM(int totalVertices, int leftVertices)
      : V(totalVertices), Vleft(leftVertices) {
    AL.assign(V, std::vector<int>());
    match.assign(V, -1);
  }

  // Add an edge from left vertex L to right vertex R
  void addEdge(int L, int R) { AL[L].push_back(R); }

  // Run the Maximum Cardinality Bipartite Matching algorithm
  int findMaximumMatching(bool useGreedy = true) {
    // Reset matching
    match.assign(V, -1);
    int MCBM = 0;

    std::unordered_set<int> freeV;
    for (int L = 0; L < Vleft; ++L) {
      freeV.insert(L);  // initial assumption: all left vertices are free
    }

    // Greedy pre-processing for trivial Augmenting Paths
    if (useGreedy) {
      for (int L = 0; L < Vleft; ++L) {  // O(V+E)
        std::vector<int> candidates;
        for (auto& R : AL[L]) {
          if (match[R] == -1) {
            candidates.push_back(R);
          }
        }

        if (!candidates.empty()) {
          ++MCBM;
          freeV.erase(L);                      // L is matched
          int a = rand() % candidates.size();  // randomize this
          match[candidates[a]] = L;
        }
      }
    }

    // For each free vertex, try to find an augmenting path
    for (auto& f : freeV) {  // (in random order)
      vis.assign(Vleft, 0);  // reset first
      MCBM += Aug(f);        // try to match f
    }

    return MCBM;
  }

  // Get the current matching
  const std::vector<int>& getMatching() const { return match; }

  // Find minimum vertex cover based on König's theorem
  std::vector<std::pair<int, int>> findMinVertexCover() {
    // First find maximum matching
    findMaximumMatching();

    // Initialize visited arrays for both partitions
    std::vector<bool> visitedLeft(Vleft, false);
    std::vector<bool> visitedRight(V - Vleft, false);

    // Queue for BFS
    std::queue<int> q;

    // Start from unmatched vertices in left partition
    for (int L = 0; L < Vleft; ++L) {
      bool isMatched = false;
      for (int R = Vleft; R < V; ++R) {
        if (match[R] == L) {
          isMatched = true;
          break;
        }
      }

      if (!isMatched) {
        q.push(L);
        visitedLeft[L] = true;
      }
    }

    // Perform BFS to find reachable vertices
    while (!q.empty()) {
      int u = q.front();
      q.pop();

      if (u < Vleft) {  // Left partition
        // Visit all adjacent vertices in right partition
        for (int R : AL[u]) {
          if (!visitedRight[R - Vleft]) {
            visitedRight[R - Vleft] = true;
            if (match[R] != -1) {
              q.push(match[R]);
              visitedLeft[match[R]] = true;
            }
          }
        }
      }
    }

    // Minimum vertex cover consists of:
    // - Left vertices NOT reachable from unmatched vertices
    // - Right vertices reachable from unmatched vertices
    std::vector<std::pair<int, int>>
        cover;  // (vertex, side) where side is 0 for left, 1 for right

    for (int L = 0; L < Vleft; ++L) {
      if (!visitedLeft[L]) {
        cover.push_back({L, 0});
      }
    }

    for (int R = 0; R < V - Vleft; ++R) {
      if (visitedRight[R]) {
        cover.push_back({R + Vleft, 1});
      }
    }

    return cover;
  }

 private:
  int V;                             // Total number of vertices
  int Vleft;                         // Number of vertices in left set
  std::vector<std::vector<int>> AL;  // Adjacency list for the graph
  std::vector<int> match;            // Stores the matching
  std::vector<int> vis;              // Visited array for augmenting path

  // Augmenting path algorithm
  int Aug(int L) {
    if (vis[L]) {
      return 0;  // L visited, return 0
    }
    vis[L] = 1;
    for (auto& R : AL[L]) {
      if ((match[R] == -1) || Aug(match[R])) {
        match[R] = L;  // flip status
        return 1;      // found 1 matching
      }
    }
    return 0;  // no matching
  }
};
