// Source - https://stackoverflow.com/a
// Posted by Leos313, modified by community. See post 'Timeline' for change history
// Retrieved 2025-11-27, License - CC BY-SA 4.0

#include "lamefft.h"

#include <complex>
#include <cassert>
#include <cmath>

using namespace std;

//#define M_PI 3.1415926535897932384

int log2(int N)    /*function to calculate the log2(.) of int numbers*/
{
  int k = N, i = 0;
  while(k) {
    k >>= 1;
    i++;
  }
  return i - 1;
}

int check(int n)    //checking if the number of element is a power of 2 and less than FFT_MAX
{
  return n > 0 && (n & (n - 1)) == 0 && n <= FFT_MAX;
}

int reverse(int N, int n)    //calculating revers number
{
  int j, p = 0;
  for(j = 1; j <= log2(N); j++) {
    if(n & (1 << (log2(N) - j)))
      p |= 1 << (j - 1);
  }
  return p;
}

void ordina(complex<double>* f1, int N) //using the reverse order in the array
{
  complex<double> f2[FFT_MAX];
  for(int i = 0; i < N; i++)
    f2[i] = f1[reverse(N, i)];
  for(int j = 0; j < N; j++)
    f1[j] = f2[j];
}

void transform(complex<double>* f, int N) //
{
  ordina(f, N);    //first: reverse order
  complex<double> *W;
  W = (complex<double> *)malloc(N / 2 * sizeof(complex<double>));
  W[1] = polar(1., -2. * M_PI / N);
  W[0] = 1;
  for(int i = 2; i < N / 2; i++)
    W[i] = pow(W[1], i);
  int n = 1;
  int a = N / 2;
  for(int j = 0; j < log2(N); j++) {
    for(int i = 0; i < N; i++) {
      if(!(i & n)) {
        complex<double> temp = f[i];
        complex<double> Temp = W[(i * a) % (n * a)] * f[i + n];
        f[i] = temp + Temp;
        f[i + n] = temp - Temp;
      }
    }
    n *= 2;
    a = a / 2;
  }
  free(W);
}

void FFT(complex<double>* f, int N)
{
  check(N);
  transform(f, N);
}

void C_FFT_real(double* f, int N)
{
  assert(check(N));
  complex<double> f_complex[FFT_MAX];
  for(int i = 0; i < N; i++)
    f_complex[i] = complex<double>(f[i], 0.0);
  transform(f_complex, N);
  for(int j = 0; j < N; j++)
    f[j] = abs(f_complex[j]); //store magnitude back in f
}