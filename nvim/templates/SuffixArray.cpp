#include <algorithm>
#include <cstring>
#include <numeric>
#include <string_view>
#include <utility>
#include <vector>

class SuffixArray {
 private:
  std::vector<int> ra;  // rank array

  void countingSort(int k) {
    int maxi = std::max(300, n);
    std::vector<int> c(maxi, 0);
    for (int i = 0; i < n; ++i) {
      ++c[i + k < n ? ra[i + k] : 0];
    }
    for (int i = 0, sum = 0; i < maxi; ++i) {
      int t = c[i];
      c[i] = sum;
      sum += t;
    }
    std::vector<int> tempSA(n);
    for (int i = 0; i < n; ++i) {
      tempSA[c[sa[i] + k < n ? ra[sa[i] + k] : 0]++] = sa[i];
    }
    std::swap(sa, tempSA);
  }

  void constructSA() {
    sa.resize(n);
    std::iota(sa.begin(), sa.end(), 0);
    ra.resize(n);
    for (int i = 0; i < n; ++i) {
      ra[i] = t[i];
    }
    for (int k = 1; k < n; k <<= 1) {
      countingSort(k);
      countingSort(0);
      std::vector<int> tempRA(n);
      int r = 0;
      tempRA[sa[0]] = r;
      for (int i = 1; i < n; ++i) {
        tempRA[sa[i]] = ((ra[sa[i]] == ra[sa[i - 1]]) &&
                         (ra[sa[i] + k] == ra[sa[i - 1] + k]))
                            ? r
                            : ++r;
      }
      std::swap(ra, tempRA);
      if (ra[sa[n - 1]] == n - 1) {
        break;
      }
    }
  }

  void computeLCP() {
    std::vector<int> phi(n);
    std::vector<int> plcp(n);
    phi[sa[0]] = -1;
    for (int i = 1; i < n; ++i) {
      phi[sa[i]] = sa[i - 1];
    }
    for (int i = 0, L = 0; i < n; ++i) {
      if (phi[i] == -1) {
        plcp[i] = 0;
        continue;
      }
      while ((i + L < n) && (phi[i] + L < n) && (t[i + L] == t[phi[i] + L])) {
        ++L;
      }
      plcp[i] = L;
      L = std::max(L - 1, 0);
    }
    lcp.resize(n);
    for (int i = 0; i < n; ++i) {
      lcp[i] = plcp[sa[i]];
    }
  }

 public:
  const char* t;
  const int n;
  std::vector<int> sa;
  std::vector<int> lcp;

  SuffixArray(const char* initialT, int _n) : t(initialT), n(_n) {
    constructSA();
    computeLCP();
  }

  std::pair<int, int> stringMatching(const char* p) {
    int m = static_cast<int>(strlen(p));
    int lo = 0, hi = n - 1;
    while (lo < hi) {
      int mid = (lo + hi) / 2;
      int res = strncmp(t + sa[mid], p, m);
      (res >= 0) ? hi = mid : lo = mid + 1;
    }
    if (strncmp(t + sa[lo], p, m) != 0) {
      return {-1, -1};
    }
    std::pair<int, int> ans;
    ans.first = lo;
    hi = n - 1;
    while (lo < hi) {
      int mid = (lo + hi) / 2;
      int res = strncmp(t + sa[mid], p, m);
      (res > 0) ? hi = mid : lo = mid + 1;
    }
    if (strncmp(t + sa[hi], p, m) != 0) {
      --hi;
    }
    ans.second = hi;
    return ans;
  }

  std::pair<int, int> findLRS() {
    int idx = 0, maxLCP = -1;
    for (int i = 1; i < n; ++i) {
      if (lcp[i] > maxLCP) {
        maxLCP = lcp[i];
        idx = i;
      }
    }
    return {maxLCP, idx};
  }

  std::pair<int, int> findLCS(int splitIdx) {
    int idx = 0, maxLCP = -1;
    for (int i = 1; i < n; ++i) {
      if ((sa[i] < splitIdx) == (sa[i - 1] < splitIdx)) {
        continue;
      }
      if (lcp[i] > maxLCP) {
        maxLCP = lcp[i];
        idx = i;
      }
    }
    return {maxLCP, idx};
  }

  // Counts distinct repeated substrings based on adjacent LCP differences
  long long countDistinctRepeatedSubstrings() {
    long long count = 0;

    // Count only when the next LCP is greater than the current one
    for (int i = 0; i < n - 1; ++i) {
      if (lcp[i + 1] > lcp[i]) {
        count += lcp[i + 1] - lcp[i];
      }
    }

    return count;
  }
};

// Example usage:
/*
const int MAX_N = 450010;

char text[MAX_N];
char pattern[MAX_N];
char lrsAns[MAX_N];
char lcsAns[MAX_N];

int main() {
  // Read input
  scanf("%s", text);
  int n = static_cast<int>(strlen(text));
  text[n++] = '$';

  SuffixArray s(text, n);

  // String matching demo
  strcpy(pattern, "A");
  auto [lb, ub] = s.stringMatching(pattern);

  // Find LRS (Longest Repeated Substring)
  auto [lrsLen, lrsIdx] = s.findLRS();

  // Find LCS (Longest Common Substring)
  strcpy(pattern, "CATA");
  int m = static_cast<int>(strlen(pattern));
  strcat(text, pattern);
  strcat(text, "#");
  n = static_cast<int>(strlen(text));

  SuffixArray s2(text, n);
  int splitIdx = n - m - 1;
  auto [lcsLen, lcsIdx] = s2.findLCS(splitIdx);

  return 0;
}
*/
