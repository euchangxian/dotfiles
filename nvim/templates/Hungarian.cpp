#include <utility>
#include <vector>

/**
 * Hungarian Algorithm for Minimum Cost Bipartite Matching
 * Description: Matches each node on the left with a node on the right
 * such that the sum of edge weights is minimized.
 *
 * @param costMatrix Cost matrix where costMatrix[i][j] = cost for matching left
 * node i with right node j
 * @return Pair of (minimum cost, matching array) where matching[i] is the right
 * node matched to left node i
 *
 * Time Complexity: O(N^2*M) where N is number of left nodes, M is number of
 * right nodes
 */
std::pair<int, std::vector<int>> hungarian(
    const std::vector<std::vector<int>>& costMatrix) {
  if (costMatrix.empty()) {
    return {0, {}};
  }

  int leftSize = costMatrix.size() + 1;
  int rightSize = costMatrix[0].size() + 1;

  // Potential values for dual linear program
  std::vector<int> leftPot(leftSize);
  std::vector<int> rightPot(rightSize);

  // Matching: rightMatch[j] = i means right node j is matched to left node i
  std::vector<int> rightMatch(rightSize);

  // Final result: matching for each left node
  std::vector<int> result(leftSize - 1, -1);

  // For each left node
  for (int left = 1; left < leftSize; left++) {
    rightMatch[0] = left;  // Set dummy node

    int j0 = 0;
    std::vector<int> dist(rightSize, INT_MAX);
    std::vector<int> prev(rightSize, -1);
    std::vector<bool> visited(rightSize + 1, false);

    // Find shortest augmenting path with Dijkstra's algorithm
    do {
      visited[j0] = true;
      int i0 = rightMatch[j0];
      int j1 = 0;
      int delta = INT_MAX;

      // Update distances for all unvisited right nodes
      for (int right = 1; right < rightSize; right++) {
        if (!visited[right]) {
          // Reduced cost (with respect to potentials)
          int cost =
              costMatrix[i0 - 1][right - 1] - leftPot[i0] - rightPot[right];

          if (cost < dist[right]) {
            dist[right] = cost;
            prev[right] = j0;
          }

          if (dist[right] < delta) {
            delta = dist[right];
            j1 = right;
          }
        }
      }

      // Update potentials
      for (int j = 0; j < rightSize; j++) {
        if (visited[j]) {
          leftPot[rightMatch[j]] += delta;
          rightPot[j] -= delta;
        } else {
          dist[j] -= delta;
        }
      }

      j0 = j1;

      // Continue until we find an unmatched right node
    } while (rightMatch[j0] != 0);

    // Update matching along the augmenting path
    while (j0 != 0) {
      int j1 = prev[j0];
      rightMatch[j0] = rightMatch[j1];
      j0 = j1;
    }
  }

  // Extract final matching
  for (int right = 1; right < rightSize; right++) {
    if (rightMatch[right] != 0) {
      result[rightMatch[right] - 1] = right - 1;
    }
  }

  return {-rightPot[0], result};  // Return minimum cost and matching
}
