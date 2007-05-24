/*
 * File:        LevelSetMethodPatchStrategy.NDIM.cc
 * Copyright:   (c) 2005-2006 Kevin T. Chu
 * Revision:    $Revision: 1.4 $
 * Modified:    $Date: 2006/10/02 00:47:34 $
 * Description: Explicit template instantiation of LSMLIB classes 
 */

#include "SAMRAI_config.h"

#include "LevelSetMethodPatchStrategy.h"
#include "LevelSetMethodPatchStrategy.cc"

template class LSMLIB::LevelSetMethodPatchStrategy<NDIM>;
