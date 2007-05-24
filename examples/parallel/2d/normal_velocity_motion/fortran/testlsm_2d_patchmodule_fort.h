/*
 * File:        testlsm_2d_patchmodule.h
 * Copyright:   (c) 2005-2006 Kevin T. Chu
 * Revision:    $Revision: 1.2 $
 * Modified:    $Date: 2006/01/24 21:46:00 $
 * Description: Header file for patch module routines for 2d LSM test problem
 */

#ifndef included_lsmtest_2d_patchmodule
#define included_lsmtest_2d_patchmodule

/* Link between C/C++ and Fortran function names
 *
 *      name in               name in
 *      C/C++ code            Fortran code
 *      ----------            ------------
 */
#define INIT_CIRCLE           initcircle_
#define INIT_LOBES            initlobes_

void INIT_CIRCLE(
  const double* level_set,
  const int* ilo_gb,
  const int* ihi_gb,
  const int* jlo_gb,
  const int* jhi_gb,
  const int* ilo_fb,
  const int* ihi_fb,
  const int* jlo_fb,
  const int* jhi_fb,
  const double* x_lower,
  const double* dx,
  const double* center,
  const double* radius);

void INIT_LOBES(
  const double* level_set,
  const int* ilo_gb,
  const int* ihi_gb,
  const int* jlo_gb,
  const int* jhi_gb,
  const int* ilo_fb,
  const int* ihi_fb,
  const int* jlo_fb,
  const int* jhi_fb,
  const double* x_lower,
  const double* dx,
  const double* center,
  const double* radius,
  const int* num_lobes);

#endif
