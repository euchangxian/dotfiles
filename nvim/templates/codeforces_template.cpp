#include <algorithm>
#include <array>
#include <bitset>
#include <climits>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <deque>
#include <functional>
#include <iomanip>
#include <ios>
#include <iostream>
#include <istream>
#include <iterator>
#include <limits>
#include <map>
#include <numeric>
#include <ostream>
#include <queue>
#include <ranges>
#include <set>
#include <span>
#include <sstream>
#include <stack>
#include <string>
#include <string_view>
#include <unordered_map>
#include <unordered_set>
#include <utility>
#include <vector>
#ifdef DEBUG
#include "../Debug.cpp"
#endif  // DEBUG

#define read(arr, l, r)       \
  for (int i = l; i < r; ++i) \
  std::cin >> arr[i]

using i64 = long long;
constexpr int MOD = 1'000'000'007;

void solve() {
  //
}

int main() {
  std::ios_base::sync_with_stdio(false);
  std::cin.tie(nullptr);
  std::cout.tie(nullptr);

  int tc{1};
  std::cin >> tc;

  while (tc--) {
    solve();
  }

  return 0;
}
