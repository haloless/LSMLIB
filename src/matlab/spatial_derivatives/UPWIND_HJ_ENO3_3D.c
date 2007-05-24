/*
 * File:        UPWIND_HJ_ENO3_3D.c
 * Copyright:   (c) 2005-2006 Kevin T. Chu
 * Revision:    $Revision: 1.15 $
 * Modified:    $Date: 2006/09/18 20:27:33 $
 * Description: MATLAB MEX-file for 3d, third-order upwind HJ ENO 
 */

/*=======================================================================
 *
 * UPWIND_HJ_ENO3_3D() computes the third-order upwind HJ ENO
 * approximation to grad(phi)
 *
 * Usage: [phi_x, phi_y, phi_z] = ...
 *        UPWIND_HJ_ENO3_3D(phi, vel_x, vel_y, vel_z, ghostcell_width, dX)
 *
 * Arguments:
 * - phi:              function for which to compute upwind
 *                       derivative
 * - vel_x:            x-component of velocity to use in upwinding
 * - vel_y:            y-component of velocity to use in upwinding
 * - vel_z:            z-component of velocity to use in upwinding
 * - ghostcell_width:  number of ghostcells at boundary of
 *                       computational domain
 * - dX:               array containing the grid spacing
 *                       in coordinate directions
 *
 * Return values:
 * - phi_x:            x-component of third-order, upwind 
 *                       HJ ENO derivative
 * - phi_y:            y-component of third-order, upwind 
 *                       HJ ENO derivative
 * - phi_z:            z-component of third-order, upwind 
 *                       HJ ENO derivative
 *
 * NOTES:
 * - The vel_x, vel_y, and vel_z arrays are assumed to be the same 
 *   size.
 *
 * - phi_x, phi_y, and phi_z have the same ghostcell width as phi.
 *
 * - All data arrays are assumed to be in the order generated by the
 *   MATLAB meshgrid() function.  That is, data corresponding to the
 *   point (x_i,y_j,z_k) is stored at index (j,i,k).  The output data 
 *   arrays will be returned with the same ordering as the input data 
 *   arrays.
 *
 *=======================================================================*/

#include "mex.h"
#include "matrix.h"
#include "lsm_spatial_derivatives3d.h"

/* Input Arguments */ 
#define PHI             (prhs[0])
#define VEL_X           (prhs[1])
#define VEL_Y           (prhs[2])
#define VEL_Z           (prhs[3])
#define GHOSTCELL_WIDTH (prhs[4])
#define DX              (prhs[5])

/* Output Arguments */ 
#define PHI_X           (plhs[0])
#define PHI_Y           (plhs[1])
#define PHI_Z           (plhs[2])

/* Other Macros */ 
#define NDIM            (3)


void mexFunction( int nlhs, mxArray *plhs[], 
		  int nrhs, const mxArray*prhs[] )
     
{ 
  double *phi_x, *phi_y, *phi_z;
  int ilo_grad_phi_gb, ihi_grad_phi_gb;
  int jlo_grad_phi_gb, jhi_grad_phi_gb;
  int klo_grad_phi_gb, khi_grad_phi_gb;
  double *phi; 
  int ilo_phi_gb, ihi_phi_gb, jlo_phi_gb, jhi_phi_gb, klo_phi_gb, khi_phi_gb;
  double *vel_x, *vel_y, *vel_z;
  int ilo_vel_gb, ihi_vel_gb, jlo_vel_gb, jhi_vel_gb, klo_vel_gb, khi_vel_gb;
  double *D1;
  int ilo_D1_gb, ihi_D1_gb, jlo_D1_gb, jhi_D1_gb, klo_D1_gb, khi_D1_gb;
  double *D2;
  int ilo_D2_gb, ihi_D2_gb, jlo_D2_gb, jhi_D2_gb, klo_D2_gb, khi_D2_gb;
  double *D3;
  int ilo_D3_gb, ihi_D3_gb, jlo_D3_gb, jhi_D3_gb, klo_D3_gb, khi_D3_gb;
  int ilo_fb, ihi_fb, jlo_fb, jhi_fb, klo_fb, khi_fb;
  double *dX;
  double dX_meshgrid_order[3];
  int ghostcell_width;
  int num_data_array_dims;
  const int *data_array_dims_in;
  int data_array_dims_out[NDIM];
  
  /* Check for proper number of arguments */
  if (nrhs != 6) { 
    mexErrMsgTxt("Six required input arguments."); 
  } else if (nlhs > 3) {
    mexErrMsgTxt("Too many output arguments."); 
  } 
    
  /* Parameter Checks */
  num_data_array_dims = mxGetNumberOfDimensions(PHI);
  if (num_data_array_dims != 3) {
    mexErrMsgTxt("phi should be a 3 dimensional array."); 
  }
  num_data_array_dims = mxGetNumberOfDimensions(VEL_X);
  if (num_data_array_dims != 3) {
    mexErrMsgTxt("vel_x should be a 3 dimensional array."); 
  }
  num_data_array_dims = mxGetNumberOfDimensions(VEL_Y);
  if (num_data_array_dims != 3) {
    mexErrMsgTxt("vel_y should be a 3 dimensional array."); 
  }
  num_data_array_dims = mxGetNumberOfDimensions(VEL_Z);
  if (num_data_array_dims != 3) {
    mexErrMsgTxt("vel_z should be a 3 dimensional array."); 
  }

  /* Get ghostcell_width */
  ghostcell_width = mxGetPr(GHOSTCELL_WIDTH)[0];

  /* Get dX */
  dX = mxGetPr(DX);

  /* Change order of dX to be match MATLAB meshgrid() order for grids. */
  dX_meshgrid_order[0] = dX[1];
  dX_meshgrid_order[1] = dX[0];
  dX_meshgrid_order[2] = dX[2];

  /* Assign pointers for phi and velocities */
  phi = mxGetPr(PHI);
  vel_x = mxGetPr(VEL_X);
  vel_y = mxGetPr(VEL_Y);
  vel_z = mxGetPr(VEL_Z);
      
  /* Get size of phi data */
  data_array_dims_in = mxGetDimensions(PHI);
  ilo_phi_gb = 1;
  ihi_phi_gb = data_array_dims_in[0];
  jlo_phi_gb = 1;
  jhi_phi_gb = data_array_dims_in[1];
  klo_phi_gb = 1;
  khi_phi_gb = data_array_dims_in[2];

  /* Get size of velocity data                       */
  /* (assume vel_x, vel_y, and vel_z have same size) */
  data_array_dims_in = mxGetDimensions(VEL_X);
  ilo_vel_gb = 1;
  ihi_vel_gb = data_array_dims_in[0];
  jlo_vel_gb = 1;
  jhi_vel_gb = data_array_dims_in[1];
  klo_vel_gb = 1;
  khi_vel_gb = data_array_dims_in[2];

  /* if necessary, shift ghostbox for velocity to be */
  /* centered with respect to the ghostbox for phi.  */
  if (ihi_vel_gb != ihi_phi_gb) {
    int shift = (ihi_phi_gb-ihi_vel_gb)/2;
    ilo_vel_gb += shift;
    ihi_vel_gb += shift;
  }
  if (jhi_vel_gb != jhi_phi_gb) {
    int shift = (jhi_phi_gb-jhi_vel_gb)/2;
    jlo_vel_gb += shift;
    jhi_vel_gb += shift;
  }
  if (khi_vel_gb != khi_phi_gb) {
    int shift = (khi_phi_gb-khi_vel_gb)/2;
    klo_vel_gb += shift;
    khi_vel_gb += shift;
  }

  /* Create matrices for upwind derivatives (i.e. phi_x, phi_y, phi_z) */
  ilo_grad_phi_gb = ilo_phi_gb;
  ihi_grad_phi_gb = ihi_phi_gb;
  jlo_grad_phi_gb = jlo_phi_gb;
  jhi_grad_phi_gb = jhi_phi_gb;
  klo_grad_phi_gb = klo_phi_gb;
  khi_grad_phi_gb = khi_phi_gb;
  data_array_dims_out[0] = ihi_grad_phi_gb-ilo_grad_phi_gb+1;
  data_array_dims_out[1] = jhi_grad_phi_gb-jlo_grad_phi_gb+1;
  data_array_dims_out[2] = khi_grad_phi_gb-klo_grad_phi_gb+1;
  PHI_X = mxCreateNumericArray(NDIM, data_array_dims_out,
          mxDOUBLE_CLASS, mxREAL);
  phi_x = mxGetPr(PHI_X); 
  PHI_Y = mxCreateNumericArray(NDIM, data_array_dims_out,
          mxDOUBLE_CLASS, mxREAL);
  phi_y = mxGetPr(PHI_Y); 
  PHI_Z = mxCreateNumericArray(NDIM, data_array_dims_out,
          mxDOUBLE_CLASS, mxREAL);
  phi_z = mxGetPr(PHI_Z); 

  /* Allocate scratch memory for undivided differences */
  ilo_D1_gb = ilo_phi_gb;
  ihi_D1_gb = ihi_phi_gb;
  jlo_D1_gb = jlo_phi_gb;
  jhi_D1_gb = jhi_phi_gb;
  klo_D1_gb = klo_phi_gb;
  khi_D1_gb = khi_phi_gb;
  D1 = (double*) malloc( sizeof(double) 
                       * (ihi_D1_gb-ilo_D1_gb+1)
                       * (jhi_D1_gb-jlo_D1_gb+1)
                       * (khi_D1_gb-klo_D1_gb+1) );

  ilo_D2_gb = ilo_phi_gb;
  ihi_D2_gb = ihi_phi_gb;
  jlo_D2_gb = jlo_phi_gb;
  jhi_D2_gb = jhi_phi_gb;
  klo_D2_gb = klo_phi_gb;
  khi_D2_gb = khi_phi_gb;
  D2 = (double*) malloc( sizeof(double) 
                       * (ihi_D2_gb-ilo_D2_gb+1)
                       * (jhi_D2_gb-jlo_D2_gb+1)
                       * (khi_D2_gb-klo_D2_gb+1) );

  ilo_D3_gb = ilo_phi_gb;
  ihi_D3_gb = ihi_phi_gb;
  jlo_D3_gb = jlo_phi_gb;
  jhi_D3_gb = jhi_phi_gb;
  klo_D3_gb = klo_phi_gb;
  khi_D3_gb = khi_phi_gb;
  D3 = (double*) malloc( sizeof(double) 
                       * (ihi_D3_gb-ilo_D3_gb+1)
                       * (jhi_D3_gb-jlo_D3_gb+1)
                       * (khi_D3_gb-klo_D3_gb+1) );

  if ( (!D1) || (!D2) || (!D3) ) {
    if (D1) free(D1);
    if (D2) free(D2);
    if (D3) free(D3);
    mexErrMsgTxt("Unable to allocate memory for scratch data...aborting....");
  }


  /* Do the actual computations in a Fortran 77 subroutine */
  ilo_fb = ilo_phi_gb+ghostcell_width;
  ihi_fb = ihi_phi_gb-ghostcell_width;
  jlo_fb = jlo_phi_gb+ghostcell_width;
  jhi_fb = jhi_phi_gb-ghostcell_width;
  klo_fb = klo_phi_gb+ghostcell_width;
  khi_fb = khi_phi_gb-ghostcell_width;

  /* 
   * NOTE: ordering of data arrays from meshgrid() is (y,x,z), so 
   * order derivative and velocity data arrays need to be permuted.
   */
  LSM3D_UPWIND_HJ_ENO3(
    phi_y, phi_x, phi_z,
    &ilo_grad_phi_gb, &ihi_grad_phi_gb,
    &jlo_grad_phi_gb, &jhi_grad_phi_gb,
    &klo_grad_phi_gb, &khi_grad_phi_gb,
    phi, 
    &ilo_phi_gb, &ihi_phi_gb, 
    &jlo_phi_gb, &jhi_phi_gb, 
    &klo_phi_gb, &khi_phi_gb, 
    vel_y, vel_x, vel_z,
    &ilo_vel_gb, &ihi_vel_gb, 
    &jlo_vel_gb, &jhi_vel_gb,
    &klo_vel_gb, &khi_vel_gb,
    D1,
    &ilo_D1_gb, &ihi_D1_gb, 
    &jlo_D1_gb, &jhi_D1_gb, 
    &klo_D1_gb, &khi_D1_gb, 
    D2,
    &ilo_D2_gb, &ihi_D2_gb, 
    &jlo_D2_gb, &jhi_D2_gb, 
    &klo_D2_gb, &khi_D2_gb, 
    D3,
    &ilo_D3_gb, &ihi_D3_gb, 
    &jlo_D3_gb, &jhi_D3_gb, 
    &klo_D3_gb, &khi_D3_gb, 
    &ilo_fb, &ihi_fb, 
    &jlo_fb, &jhi_fb,
    &klo_fb, &khi_fb,
    &dX_meshgrid_order[0], &dX_meshgrid_order[1], &dX_meshgrid_order[2]);

  /* Deallocate scratch memory for undivided differences */
  free(D1);
  free(D2);
  free(D3);

  return;
}


