// Source - https://stackoverflow.com/a
// Posted by Leos313, modified by community. See post 'Timeline' for change history
// Retrieved 2025-11-27, License - CC BY-SA 4.0

#pragma once

#define FFT_MAX 1024

#ifdef __cplusplus

// f is a array fo compex numbers that is changed in place
// N must be less than FFT_MAX and must be a power of two

#include <complex>
void FFT(std::complex<double>* f, int N);

extern "C" {
#endif

// A C callable FFT function that works on a real-valued input array 
// and modifies the array to contain the magnitude of the FFT

void C_FFT_real(double* f, int N);

#ifdef __cplusplus
}
#endif

