/*
 * File:        lsm_grid.h
 * Copyright:   (c) 2005-2006 Masa Prodanovic and Kevin T. Chu
 * Revision:    $Revision: 1.4 $
 * Modified:    $Date: 2006/09/18 20:38:08 $
 * Description: Header file for grid data structures that support serial
 *              LSMLIB calculations
 */

#ifndef included_lsm_grid_h
#define included_lsm_grid_h

#ifdef __cplusplus
extern "C" {
#endif

#include <stdio.h>


/*! \file lsm_grid.h
 *
 * \brief
 * @ref lsm_grid.h provides support for managing 2D & 3D grids that are 
 * used by serial level set method calculations.
 *
 */


/*!
 * The 'Grid' structure contains the basic information about the 
 * geometric dimensions and index space (i.e. number of grid
 * cells, fill box and ghost box limits) for the data arrays used
 * in level set method calculations.
 *
 * NOTE:
 * - The same data structure can be used for both 2D and 3D 
 *   calculations.
 *
 */
typedef struct _Grid {

   /* dimension (2 or 3) */
   int      num_dims;

   /* lower and upper geometric limits in each coordinate direction */
   /* for the interior of the computational domain (user specified) */
   double   x_lo[3];
   double   x_hi[3];

   /* lower and upper geometric limits in each coordinate direction */
   /* for the entire computational grid INCLUDING the ghostcells    */
   double   x_lo_ghostbox[3]; 
   double   x_hi_ghostbox[3];

   /* number of grid points in each coordinate direction for the */
   /* interior of the comptuational domain (user specified)      */ 
   int      grid_dims[3];

   /* number of grid points in each coordinate direction for the */
   /* entire computational domain INCLUDING the ghostcells       */
   int      grid_dims_ghostbox[3];

   /* grid spacing in each coordinate direction */
   double   dx[3];

   /* total number of gridpoints */  
   int      num_gridpts;
   
   /* index space for ghostbox of field variables                     */
  /* NOTE: the ghostbox is assumed to be the same for all variables. */
  int ilo_gb, ihi_gb, jlo_gb, jhi_gb, klo_gb, khi_gb;
  
  /* index space for interior of grid (i.e. fillbox) */
  int ilo_fb, ihi_fb, jlo_fb, jhi_fb, klo_fb, khi_fb;
 
  /* index spaces for fillbox of undivided differenced */
  /* (used in calculation of spatial derivatives)      */
  int ilo_D1_fb, ihi_D1_fb, jlo_D1_fb, jhi_D1_fb, klo_D1_fb, khi_D1_fb;
  int ilo_D2_fb, ihi_D2_fb, jlo_D2_fb, jhi_D2_fb, klo_D2_fb, khi_D2_fb;
  int ilo_D3_fb, ihi_D3_fb, jlo_D3_fb, jhi_D3_fb, klo_D3_fb, khi_D3_fb;

 } Grid;
 
 
/*! \enum LSMLIB_SPATIAL_DERIVATIVE_ACCURACY_TYPE
 *
 * Enumerated type for specifying the desired accuracy level for spatial
 * derivatives.
 * "LOW" accuracy assumes HJ ENO1 (1st order) scheme will be used for 
 * spatial derivatives, "MEDIUM" corresponds to HJ ENO2, "HIGH" to HJ ENO3
 * and "VERY_HIGH" to HJ WENO5.
 */
typedef enum { LOW = 0, MEDIUM = 1, HIGH = 2, VERY_HIGH = 3 } 
  LSMLIB_SPATIAL_DERIVATIVE_ACCURACY_TYPE;


/*! @{ 
 ****************************************************************
 *
 * @name Grid management functions
 *
 ****************************************************************/
 
/*!
 *  createGridSetDx() allocates and defines the elements in the Grid 
 *  structure for problems in 2D or 3D when the grid spacing, dx,
 *  is specified by the user.
 *
 * Arguments:
 *  - num_dims (in):  desired spatial dimension for problem (2 or 3)
 *  - dx (in):        desired grid spacing (same in all dim's)
 *  - x_lo (in):      physical/geometric coordinates of the lower
 *                    corner of the interior of the computational 
 *                    domain (i.e. without ghostcells)
 *  - x_hi (in):      physical/geometric coordinates of the upper
 *                    corner of the interior of the computational 
 *                    domain (i.e. without ghostcells)
 *  - accuracy (in):  desired accuracy ("LOW","MEDIUM","HIGH" or
 *                    "VERY_HIGH")
 *
 * Return value:      pointer to the newly created Grid structure
 *
 * NOTES: 
 * - x_hi may be reset to ensure that (x_hi-x_lo) is an integer 
 *   multiple of dx.
 * 
 * - The size of the x_lo and x_hi arrays should be equal to the
 *   number of dimensions.
 *
 */
 
Grid *createGridSetDx(int num_dims, double dx, 
                      double *x_lo, double *x_hi,
                      LSMLIB_SPATIAL_DERIVATIVE_ACCURACY_TYPE accuracy);


/*!
 * createGridSetGridDims() allocates and defines the elements in the Grid 
 * structure for problems in 2D or 3D when the grid dimensions, grid_dims,
 * are specified by the user.
 *
 * Arguments:
 *  - num_dims (in):   desired spatial dimension for problem (2 or 3)
 *  - grid_dims (in):  array of integers representing the desired
 *                     dimensions for computational grid (without 
 *                     ghostcells)
 *  - x_lo (in):       physical/geometric coordinates of the lower
 *                     corner of the interior of the computational 
 *                     domain (i.e. without ghostcells)
 *  - x_hi (in):       physical/geometric coordinates of the upper
 *                     corner of the interior of the computational 
 *                     domain (i.e. without ghostcells)
 *  - accuracy (in):   desired accuracy ("LOW","MEDIUM","HIGH" or
 *                     "VERY_HIGH")
 *
 * Return value:       pointer to the newly created Grid structure
 *
 * NOTES: 
 * - The size of the grid_dims, x_lo, and x_hi arrays should be
 *   equal to the number of dimensions.
 *
 */
Grid *createGridSetGridDims(int num_dims, int *grid_dims, 
                            double *x_lo, double *x_hi,
                            LSMLIB_SPATIAL_DERIVATIVE_ACCURACY_TYPE accuracy);


/*! 
 * copyGrid() copies existing Grid structure into a new one. 
 *
 * Arguments
 *  - grid (in):  pointer to Grid structure to be copied
 *
 * Return value:  pointer to the newly created Grid structure
 *
 * NOTES:
 * - Memory for the new structure allocated within the function.
 *
 */
Grid *copyGrid(Grid *grid);


/*!
 * destroyGrid() frees memory used by the specified Grid. 
 *
 * Arguments:
 *  - grid (in):  Grid data structure to be destroyed
 *
 * Return value:  none
 *
 */
void destroyGrid(Grid *grid);


/*! 
 * printGrid() prints the Grid configuration to the specified file pointer
 * in human-readable format.
 *
 * Arguments
 *  - grid (in):  pointer to Grid structure
 *  - fp (in):    pointer to output file
 *
 * Return value:  none
 *
 * NOTES:
 * - printGrid() does NOT write out the level set data associated with 
 *   the specified grid.
 *
 */
void printGrid(Grid *grid, FILE *fp);
 
 
 /*! 
 * writeGridToAsciiFile() writes the Grid configuration to a file in 
 * ASCII format.
 *
 * Arguments
 *  - grid (in):       pointer to Grid structure
 *  - file_name (in):  name of output file
 *
 * Return value:       none
 *
 * NOTES:
 * - writeGridToAsciiFile() does NOT write out the level set data 
 *   associated with the specified grid.
 *
 * - If a file with the specified file_name already exists, it is 
 *   overwritten.
 *
 */
void writeGridToAsciiFile(Grid *grid, char *file_name);
 

/*!
 * readGridFromAsciiFile() allocates memory for a new Grid structure and
 * loads the Grid configuration from the specified ASCII file.
 *
 * Arguments:
 *  - file_name(in):  name for file containing Grid configuration
 *
 * Return value:      pointer to newly constructed Grid structure
 *
 * NOTES:
 * - The specified file must have been generated by writeGridToAsciiFile().
 *  
 * - To avoid memory leaks, the grid returned by readGridFromAsciiFile() 
 *   should be destroyed using destroyGrid() when it is no longer needed.
 *
 */
Grid *readGridFromAsciiFile(char *file_name);
 
 
/*!
 * writeGridToBinaryFile() outputs grid to a basic binary file.
 *
 * Arguments:
 *  - grid (in):       pointer to Grid structure 
 *  - file_name (in):  name of output file
 *
 * Return value:       none
 *
 * NOTES:
 * - writeGridToBinaryFile() does NOT write out the level set data 
 *   associated with the specified grid.
 *
 * - If a file with the specified file_name already exists, it is 
 *   overwritten.
 *
 */
void writeGridToBinaryFile(Grid *grid, char *file_name);


/*!
 * readGridFromBinaryFile() allocates memory for a new Grid structure and
 * loads the Grid configuration from the specified binary file. 
 *
 * Arguments:
 *  - file_name(in):  name for file containing Grid configuration 
 *                    in binary format
 *
 * Return value:      pointer to newly constructed Grid structure
 *
 * NOTES:
 * - The specified file must have been generated by writeGridToBinaryFile().
 *  
 * - To avoid memory leaks, the grid returned by readGridFromBinaryFile() 
 *   should be destroyed using destroyGrid() when it is no longer needed.
 *
 */
Grid *readGridFromBinaryFile(char *file_name);
 

/*!
 * setIndexSpaceLimits() defines limits in Grid structure for problems 
 * in 2D or 3D.
 *
 * Arguments:
 *  - accuracy (in):  desired accuracy ("LOW","MEDIUM","HIGH" or
 *                    "VERY_HIGH")
 *  - grid (in/out):  Grid data structure containing grid configuration
 *
 * Return value:      none 
 * 
 * NOTES:
 * - Grid elements other than index space limits assumed pre-set
 * 
 */
void setIndexSpaceLimits(LSMLIB_SPATIAL_DERIVATIVE_ACCURACY_TYPE accuracy, 
   Grid *grid);

 
/*! @} */

#ifdef __cplusplus
}
#endif
 
#endif
