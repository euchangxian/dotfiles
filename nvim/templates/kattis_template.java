import java.io.*;
import java.util.*;
import java.math.*;
import java.text.*;
import java.util.concurrent.*;
import java.util.function.*;
import java.util.regex.*;
import java.util.stream.*;

public class Main {
  static final int MOD = 1_000_000_007;

  static void solve() {
  }

  public static void main(String[] args) {
    FastScanner fs = new FastScanner();
    int tc = 1;
    while (tc-- > 0) {
      solve();
    }
  }

  static class FastScanner {
    BufferedReader br = new BufferedReader(new InputStreamReader(System.in));
    StringTokenizer st = new StringTokenizer("");
    String next() {
      while (!st.hasMoreTokens())
      try { 
        st = new StringTokenizer(br.readLine());
      } catch (IOException e) {}
      return st.nextToken();
    }

    int nextInt() {
      return Integer.parseInt(next());
    }
    long nextLong() {
      return Long.parseLong(next());
    }
    double nextDouble() {
      return Double.parseDouble(next());
    }
    String nextLine() {
      String str = "";
      try {
        if(st.hasMoreTokens()){
          str = st.nextToken("\n");
        } else {
          str = br.readLine();
        }
      } catch (IOException e) {}
      return str;
    }
  }
}
