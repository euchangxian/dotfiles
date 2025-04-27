#include <algorithm>
#include <utility>
#include <vector>

// Stable counting sort for non-negative integers in a[0..n)
template <int MAX_VALUE = -1>
void countingSort(std::vector<int>& a) {
  int n = a.size();
  if (n <= 1) {
    return;
  }

  // 1) find the max value if not specified
  int K = MAX_VALUE;
  if constexpr (MAX_VALUE == -1) {
    K = *std::max_element(a.begin(), a.end());
  }

  // 2) count frequencies
  std::vector<int> cnt(K + 1, 0);
  for (int x : a) {
    ++cnt[x];
  }

  // 3) prefix sums: cnt[i] = # of elements ≤ i
  for (int i = 1; i <= K; ++i) {
    cnt[i] += cnt[i - 1];
  }

  // 4) build output array (reverse scan for stability)
  std::vector<int> output(n);
  for (int i = n - 1; i >= 0; --i) {
    int x = a[i];
    output[--cnt[x]] = x;
  }

  // 5) copy back
  a = std::move(output);
}

// Stable counting sort on a[i]'s 16-bit chunk at `shift` (0 or 16)
// Used for Radix Sort
void countingSort(std::vector<long long>& a, int shift) {
  int n = a.size();
  if (n <= 1) {
    return;
  }

  const int B = 1 << 16;
  std::vector<long long> output(n);
  std::vector<int> cnt(B, 0);

  // 1) count occurrences of the 16-bit “digit”
  for (auto x : a) {
    int d = (x >> shift) & 0xFFFF;
    cnt[d]++;
  }

  // 2) prefix sums
  for (int i = 1; i < B; i++) {
    cnt[i] += cnt[i - 1];
  }

  // 3) build output (in reverse for stability)
  for (int i = n - 1; i >= 0; i--) {
    int d = (a[i] >> shift) & 0xFFFF;
    output[--cnt[d]] = a[i];
  }

  // 4) copy back
  for (int i = 0; i < n; i++) {
    a[i] = output[i];
  }
}

void radixSort(std::vector<long long>& a) {
  if (a.empty()) {
    return;
  }
  countingSort(a, 0);
  countingSort(a, 16);
}
