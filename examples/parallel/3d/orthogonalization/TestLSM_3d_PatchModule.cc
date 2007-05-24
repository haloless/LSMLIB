/*
 * File:        TestLSM_3d_PatchModule.cc
 * Copyright:   (c) 2005-2006 Kevin T. Chu
 * Revision:    $Revision: 1.1 $
 * Modified:    $Date: 2006/04/10 15:25:50 $
 * Description: Implementation for concrete subclass of 
 *              LevelSetMethodPatchStrategy that computes the single patch
 *              numerical routines for the 3d level set method test problem
 */


#include "TestLSM_3d_PatchModule.h"

#include "Box.h"
#include "CartesianPatchGeometry.h"
#include "CellData.h"

// headers for level set method numerical kernels
extern "C" {
  #include "testlsm_3d_patchmodule_fort.h"
}

// SAMRAI namespaces
using namespace geom; 
using namespace pdat; 
using namespace LSMLIB;


TestLSM_3d_PatchModule::TestLSM_3d_PatchModule(
  const string& object_name)
{
#ifdef DEBUG_CHECK_ASSERTIONS
  assert(!object_name.empty());
#endif

  // set object name and grid geometry
  d_object_name = object_name;

}

void TestLSM_3d_PatchModule::initializeLevelSetFunctionsOnPatch(
  Patch<3>& patch,
  const double data_time,
  const int phi_handle,
  const int psi_handle)
{
  Pointer< CellData<3,double> > phi_data =
    patch.getPatchData( phi_handle );
  Pointer< CellData<3,double> > psi_data =
    patch.getPatchData( psi_handle );

  double* phi = phi_data->getPointer();
  double* psi = psi_data->getPointer();

  Pointer< CartesianPatchGeometry<3> > patch_geom 
    = patch.getPatchGeometry();
  const double* dx = patch_geom->getDx();
  const double* x_lower = patch_geom->getXLower();

  Box<3> fill_box = phi_data->getBox();
  const IntVector<3> fill_box_lower = fill_box.lower();
  const IntVector<3> fill_box_upper = fill_box.upper();

  Box<3> phi_ghostbox = phi_data->getGhostBox();
  const IntVector<3> phi_ghostbox_lower = phi_ghostbox.lower();
  const IntVector<3> phi_ghostbox_upper = phi_ghostbox.upper();

  Box<3> psi_ghostbox = psi_data->getGhostBox();
  const IntVector<3> psi_ghostbox_lower = psi_ghostbox.lower();
  const IntVector<3> psi_ghostbox_upper = psi_ghostbox.upper();

  INITIALIZE_PERIODIC_ARRAY_OF_LINES(
    phi,
    &phi_ghostbox_lower[0],
    &phi_ghostbox_upper[0],
    &phi_ghostbox_lower[1],
    &phi_ghostbox_upper[1],
    &phi_ghostbox_lower[2],
    &phi_ghostbox_upper[2],
    psi,
    &psi_ghostbox_lower[0],
    &psi_ghostbox_upper[0],
    &psi_ghostbox_lower[1],
    &psi_ghostbox_upper[1],
    &psi_ghostbox_lower[2],
    &psi_ghostbox_upper[2],
    &fill_box_lower[0],
    &fill_box_upper[0],
    &fill_box_lower[1],
    &fill_box_upper[1],
    &fill_box_lower[2],
    &fill_box_upper[2],
    x_lower,
    dx);

}

void TestLSM_3d_PatchModule::setLevelSetFunctionBoundaryConditions(
    Patch<3>& patch,
    const double fill_time,
    const int phi_handle,
    const int psi_handle,
    const IntVector<3>& ghost_width_to_fill)
{
}

void TestLSM_3d_PatchModule::printClassData(ostream &os) const
{
  os << "\nTestLSM_3d_PatchModule::printClassData..." << endl;
  os << "TestLSM_3d_PatchModule: this = " << (TestLSM_3d_PatchModule*)this 
     << endl;
  os << "d_object_name = " << d_object_name << endl;
  os << endl;
}


