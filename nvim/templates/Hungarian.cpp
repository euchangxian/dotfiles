#include <limits>
#include <type_traits>
#include <utility>
#include <vector>

/**
 * Hungarian Algorithm for Minimum Cost Bipartite Matching with configurable
 * options
 *
 * Template parameters:
 * - ReturnMatching: Controls whether to return just cost or {cost, matching}
 * - ZeroIndexed: Whether input/output uses 0-indexing or 1-indexing
 * - T: Numeric type for costs and indices
 *
 * @param costMatrix Cost matrix where costMatrix[i][j] = cost for matching node
 * i with node j
 * @return Minimum cost or {min_cost, matching vector} based on ReturnMatching
 *
 * Time Complexity: O(N^2*M) where N is number of left nodes, M is number of
 * right nodes Note: #left_nodes must be <= #right_nodes
 */
template <bool ReturnMatching = false,
          bool ZeroIndexed = true,
          typename T = long long>
typename std::conditional<ReturnMatching, std::pair<T, std::vector<T>>, T>::type
Hungarian(const std::vector<std::vector<T>>& costMatrix) {
  constexpr T INF = std::numeric_limits<T>::max();

  // Adjust for indexing
  const T rowOffset = ZeroIndexed ? 1 : 0;
  const T colOffset = ZeroIndexed ? 1 : 0;

  // Determine sizes based on indexing
  const T n = ZeroIndexed ? costMatrix.size()
                          : costMatrix.size() - 1;  // Number of left nodes
  const T m = ZeroIndexed ? costMatrix[0].size()
                          : costMatrix[0].size() - 1;  // Number of right nodes

  // Create internal 1-indexed array for algorithm processing
  std::vector<std::vector<T>> a;
  if constexpr (ZeroIndexed) {
    // Convert from 0-indexed to 1-indexed for internal algorithm
    a.resize(n + 1, std::vector<T>(m + 1));
    for (T i = 0; i < n; ++i) {
      for (T j = 0; j < m; ++j) {
        a[i + 1][j + 1] = costMatrix[i][j];
      }
    }
  } else {
    // Already 1-indexed, use as is
    a = costMatrix;
  }

  // Potential values for dual linear program
  std::vector<T> u(n + 1);  // Left side potentials
  std::vector<T> v(m + 1);  // Right side potentials
  std::vector<T> p(m + 1);  // Current matching: p[j] = i means right node j is
                            // matched to left node i

  // For each left node
  for (T i = 1; i <= n; ++i) {
    p[0] = i;  // Set current left node to process
    T j0 = 0;  // Start with dummy right node

    std::vector<T> minv(m + 1, INF);  // Minimum distance to each right node
    std::vector<T> way(m + 1);        // Path tracking for augmenting path
    std::vector<bool> used(m + 1, false);  // Visited nodes in Dijkstra

    // Dijkstra algorithm to find an augmenting path
    do {
      used[j0] = true;
      T i0 = p[j0];   // Current left node
      T delta = INF;  // Minimum distance
      T j1 = 0;       // Next right node to visit

      // Update distances for all unvisited right nodes
      for (T j = 1; j <= m; ++j) {
        if (!used[j]) {
          // Calculate reduced cost
          T cur = a[i0][j] - u[i0] - v[j];

          // Update minimum distance and path
          if (cur < minv[j]) {
            minv[j] = cur;
            way[j] = j0;
          }

          // Track minimum overall distance
          if (minv[j] < delta) {
            delta = minv[j];
            j1 = j;
          }
        }
      }

      // Update potentials
      for (T j = 0; j <= m; ++j) {
        if (used[j]) {
          u[p[j]] += delta;
          v[j] -= delta;
        } else {
          minv[j] -= delta;
        }
      }

      j0 = j1;  // Move to the next right node
    } while (p[j0] != 0);  // Continue until we find an unmatched right node

    // Update matching along the augmenting path
    do {
      T j1 = way[j0];
      p[j0] = p[j1];
      j0 = j1;
    } while (j0 != 0);
  }

  // If we're not returning matching, just return the cost
  if constexpr (!ReturnMatching) {
    return -v[0];  // Return just min cost
  }

  // Extract matching based on indexing preference
  std::vector<T> matching;
  if constexpr (ZeroIndexed) {
    // Return 0-indexed matching
    matching.resize(n, -1);
    for (T j = 1; j <= m; ++j) {
      if (p[j] != 0) {
        matching[p[j] - 1] = j - 1;
      }
    }
  } else {
    // Return 1-indexed matching
    matching.resize(n + 1);
    for (T j = 1; j <= m; ++j) {
      if (p[j] != 0) {
        matching[p[j]] = j;
      }
    }
  }
  return {-v[0], matching};  // Return {min_cost, matching}
}
