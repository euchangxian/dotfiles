#include <tuple>

const int MAX_N = 200010;

char T[MAX_N], P[MAX_N];  // T = text, P = pattern
int n, m;                 // n = |T|, m = |P|

// Knuth-Morris-Pratt's algorithm specific code
int b[MAX_N];  // b = back table

void kmpPreprocess() {  // call this first
  int i = 0, j = -1;
  b[0] = -1;       // starting values
  while (i < m) {  // pre-process P
    while ((j >= 0) && (P[i] != P[j])) {
      j = b[j];  // different, reset j
    }
    ++i;
    ++j;  // same, advance both
    b[i] = j;
  }
}

int kmpSearch() {  // similar as above
  int freq = 0;
  int i = 0, j = 0;  // starting values
  while (i < n) {    // search through T
    while ((j >= 0) && (T[i] != P[j])) {
      j = b[j];  // if different, reset j
    }
    ++i;
    ++j;           // if same, advance both
    if (j == m) {  // a match is found
      ++freq;
      // printf("P is found at index %d in T\n", i-j);
      j = b[j];  // prepare j for the next
    }
  }
  return freq;
}

// Rabin-Karp's algorithm specific code
typedef long long ll;

const int p = 131;      // p and M are
const int M = 1e9 + 7;  // relatively prime

int Pow[MAX_N];  // to store p^i % M
int h[MAX_N];    // to store prefix hashes

void computeRollingHash() {      // Overall: O(n)
  Pow[0] = 1;                    // compute p^i % M
  for (int i = 1; i < n; ++i) {  // O(n)
    Pow[i] = ((ll)Pow[i - 1] * p) % M;
  }
  h[0] = 0;
  for (int i = 0; i < n; ++i) {  // O(n)
    if (i != 0) {
      h[i] = h[i - 1];  // rolling hash
    }
    h[i] = (h[i] + ((ll)T[i] * Pow[i]) % M) % M;
  }
}

int extEuclid(int a, int b, int& x, int& y) {  // pass x and y by ref
  int xx = y = 0;
  int yy = x = 1;
  while (b) {  // repeats until b == 0
    int q = a / b;
    std::tie(a, b) = std::tuple(b, a % b);
    std::tie(x, xx) = std::tuple(xx, x - q * xx);
    std::tie(y, yy) = std::tuple(yy, y - q * yy);
  }
  return a;  // returns gcd(a, b)
}

int modInverse(int b, int m) {  // returns b^(-1) (mod m)
  int x, y;
  int d = extEuclid(b, m, x, y);  // to get b*x + m*y == d
  if (d != 1) {
    return -1;  // to indicate failure
  }
  // b*x + m*y == 1, now apply (mod m) to get b*x == 1 (mod m)
  return (x + m) % m;  // this is the answer
}

int hash_fast(int L, int R) {  // O(1) hash of any substr
  if (L == 0) {
    return h[R];  // h is the prefix hashes
  }
  int ans = 0;
  ans = ((h[R] - h[L - 1]) % M + M) % M;        // compute differences
  ans = ((ll)ans * modInverse(Pow[L], M)) % M;  // remove P[L]^-1 (mod M)
  return ans;
}
