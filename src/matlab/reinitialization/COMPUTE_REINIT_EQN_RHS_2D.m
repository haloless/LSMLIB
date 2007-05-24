%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  COMPUTE_REINIT_EQN_RHS_2D() computes the right-hand side of the
%  reinitialization equation.
% 
%  Usage:  reinit_rhs = COMPUTE_REINIT_EQN_RHS_2D( ...
%                         phi, ghostcell_width, ...
%                         phi_x_plus, phi_y_plus, ...
%                         phi_x_minus, phi_y_minus, ...
%                         dX)
% 
%  Arguments:
%  - phi:               level set function
%  - ghostcell_width:   ghostcell width for phi
%  - phi_x_plus:        x-component of plus HJ ENO derivative
%  - phi_y_plus:        y-component of plus HJ ENO derivative
%  - phi_x_minus:       x-component of minus HJ ENO derivative
%  - phi_y_minus:       y-component of minus HJ ENO derivative
%  - dX:                array containing the grid spacing
%                         in coordinate directions
% 
%  Return value:
%  - reinit_rhs:        right-hand side of reinitialization equation
% 
%  NOTES:
%  - The phi_x_plus, phi_y_plus, phi_x_minus, and phi_y_minus arrays 
%    are assumed to be the same size
% 
% - All data arrays are assumed to be in the order generated by the 
%   MATLAB meshgrid() function.  That is, data corresponding to the 
%   point (x_i,y_j) is stored at index (j,i).
%
%  - The returned reinit_rhs array is the same size as phi.  However, only
%    the values of the RHS of the reinitialization evolution equation 
%    within the _interior_ of the computational grid are computed.  In 
%    other words, values of the RHS in the ghostcells are _not_ computed; 
%    the value in the ghostcells is set to 0.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Author:     Kevin T. Chu
% Copyright:  (c) 2005-2006, MAE Princeton University
% Revision:   $Revision: 1.2 $
% Modified:   $Date: 2006/09/18 16:19:47 $
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

