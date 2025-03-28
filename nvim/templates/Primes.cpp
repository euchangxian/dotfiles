#include <bitset>
#include <vector>

long long _sieve_size;
std::bitset<10000010> bs;  // 10^7 is the rough limit
std::vector<long long> p;  // compact list of primes

void sieve(long long upperbound) {  // range = [0..upperbound]
  _sieve_size = upperbound + 1;     // to include upperbound
  bs.set();                         // all 1s
  bs[0] = bs[1] = 0;                // except index 0+1
  for (long long i = 2; i < _sieve_size; ++i) {
    if (bs[i]) {
      // cross out multiples of i starting from i*i
      for (long long j = i * i; j < _sieve_size; j += i) {
        bs[j] = 0;
      }
      p.push_back(i);  // add prime i to the list
    }
  }
}

bool isPrime(long long N) {  // good enough prime test
  if (N < _sieve_size) {
    return bs[N];  // O(1) for small primes
  }
  for (int i = 0; i < (int)p.size() && p[i] * p[i] <= N; ++i) {
    if (N % p[i] == 0) {
      return false;
    }
  }
  return true;  // slow if N = large prime
}  // note: only guaranteed to work for N <= (last prime in vll p)^2

// second part
std::vector<long long> primeFactors(long long N) {  // pre-condition, N >= 1
  std::vector<long long> factors;
  for (int i = 0; i < (int)p.size() && p[i] * p[i] <= N; ++i) {
    while (N % p[i] == 0) {  // found a prime for N
      N /= p[i];             // remove it from N
      factors.push_back(p[i]);
    }
  }
  if (N != 1) {
    factors.push_back(N);  // remaining N is a prime
  }
  return factors;
}

// third part
int numPF(long long N) {
  int ans = 0;
  for (int i = 0; i < (int)p.size() && p[i] * p[i] <= N; ++i) {
    while (N % p[i] == 0) {
      N /= p[i];
      ++ans;
    }
  }
  return ans + (N != 1);
}

int numDiffPF(long long N) {
  int ans = 0;
  for (int i = 0; i < p.size() && p[i] * p[i] <= N; ++i) {
    if (N % p[i] == 0) {
      ++ans;  // count this prime factor
    }
    while (N % p[i] == 0) {
      N /= p[i];  // only once
    }
  }
  if (N != 1) {
    ++ans;
  }
  return ans;
}

long long sumPF(long long N) {
  long long ans = 0;
  for (int i = 0; i < p.size() && p[i] * p[i] <= N; ++i) {
    while (N % p[i] == 0) {
      N /= p[i];
      ans += p[i];
    }
  }
  if (N != 1) {
    ans += N;
  }
  return ans;
}

int numDiv(long long N) {
  int ans = 1;  // start from ans = 1
  for (int i = 0; i < (int)p.size() && p[i] * p[i] <= N; ++i) {
    int power = 0;  // count the power
    while (N % p[i] == 0) {
      N /= p[i];
      ++power;
    }
    ans *= power + 1;  // follow the formula
  }
  return (N != 1) ? 2 * ans : ans;  // last factor = N^1
}

long long sumDiv(long long N) {
  long long ans = 1;  // start from ans = 1
  for (int i = 0; i < (int)p.size() && p[i] * p[i] <= N; ++i) {
    long long multiplier = p[i], total = 1;
    while (N % p[i] == 0) {
      N /= p[i];
      total += multiplier;
      multiplier *= p[i];
    }  // total for
    ans *= total;  // this prime factor
  }
  if (N != 1) {
    ans *= (N + 1);  // N^2-1/N-1 = N+1
  }
  return ans;
}

long long EulerPhi(long long N) {
  long long ans = N;  // start from ans = N
  for (int i = 0; i < (int)p.size() && p[i] * p[i] <= N; ++i) {
    if (N % p[i] == 0) {
      ans -= ans / p[i];  // count unique
    }
    while (N % p[i] == 0) {
      N /= p[i];  // prime factor
    }
  }
  if (N != 1) {
    ans -= ans / N;  // last factor
  }
  return ans;
}
