c***********************************************************************
c
c  File:        lsm_spatial_derivatives1d.f
c  Copyright:   (c) 2005-2006 Kevin T. Chu
c  Revision:    $Revision: 1.16 $
c  Modified:    $Date: 2006/10/14 15:56:12 $
c  Description: F77 routines for computing 1D ENO/WENO spatial derivatives
c
c***********************************************************************

c***********************************************************************
c The algorithms and notation in these subroutines closely follows
c the discussion in Osher & Fedkiw (2003).
c***********************************************************************

c***********************************************************************
c
c  lsm1dComputeDn() computes the n-th undivided differences given the 
c  (n-1)-th undivided differences.  The undivided differences in 
c  cells with insufficient data is set to a large number.
c
c  Arguments:
c    Dn (out):           n-th undivided differences 
c    Dn_minus_one (in):  (n-1)-th undivided differences 
c    n (in):             order of undivided differences to compute
c    *_gb (in):          index range for ghostbox
c    *_fb (in):          index range for fillbox (cell-centered)
c
c
c  NOTES:
c   - The index ranges for all ghostboxes and the fillbox should 
c     correspond to the index range for cell-centered data.
c   - The undivided differences for odd n are face-centered (i.e.
c     indices are of the form (i+1/2)).  In this situation, the array
c     index corresponding to the (i+1/2)-th undivided difference is
c     i (i.e. the index shifted down to the nearest integer index). 
c   - When n is odd, Dn is computed on the faces of the grid cells
c     specified by the fillbox indices.  The index range for the 
c     undivided differences to be computed is ilo_fb to (ihi_fb+1); 
c     that is, the number of undivided difference computed is equal
c     to the number of faces associated with the fillbox grid cells
c     (ihi_fb - ilo_fb + 2).
c   - The ghostbox for Dn_minus_one MUST be at least one ghostcell width
c     larger than the fillbox.
c
c***********************************************************************
      subroutine lsm1dComputeDn(
     &  Dn,
     &  ilo_Dn_gb, ihi_Dn_gb,
     &  Dn_minus_one,
     &  ilo_Dn_minus_one_gb, ihi_Dn_minus_one_gb,
     &  ilo_fb, ihi_fb,
     &  n)
c***********************************************************************
c { begin subroutine
      implicit none

c     _gb refers to ghostbox 
c     _fb refers to fillbox 
      integer ilo_Dn_gb, ihi_Dn_gb
      integer ilo_Dn_minus_one_gb, ihi_Dn_minus_one_gb
      integer ilo_fb, ihi_fb
      double precision Dn(ilo_Dn_gb:ihi_Dn_gb)
      double precision Dn_minus_one(
     &                    ilo_Dn_minus_one_gb:ihi_Dn_minus_one_gb)
      integer n
      integer i
      integer fillbox_shift
      integer offset
      double precision sign_multiplier
      double precision big
      parameter (big=1.d10)

c     calculate offsets, fillbox shift, and sign_multiplier used 
c     when computing undivided differences.
c     NOTE:  even and odd undivided differences are taken in
c            opposite order because of the discrepancy between
c            face- and cell-centered data.  the sign discrepancy 
c            is taken into account by sign_multiplier
      if (mod(n,2).eq.1) then
        offset = 1
        sign_multiplier = 1.0
        fillbox_shift = 1
      else
        offset = -1
        sign_multiplier = -1.0
        fillbox_shift = 0
      endif

c     loop over cells with sufficient data {
      do i=ilo_fb,ihi_fb+fillbox_shift

        Dn(i) = sign_multiplier*( Dn_minus_one(i)
     &                          - Dn_minus_one(i-offset))

      enddo
c     } end loop over grid 

c     set undivided differences for cells with insufficient data to big {
      do i=ilo_Dn_gb,ilo_fb-1
        Dn(i) = big
      enddo

      do i=ihi_fb+fillbox_shift+1,ihi_Dn_gb
        Dn(i) = big
      enddo
c     } end setting big value for cells near boundary of ghostcell box

      return
      end
c } end subroutine
c***********************************************************************

c***********************************************************************
c
c  lsm1dHJENO1() computes the forward (plus) and backward (minus)
c  first-order Hamilton-Jacobi ENO approximations to the gradient of
c  phi.
c
c  Arguments:
c    phi_*_plus (out):   components of grad(phi) in plus direction
c    phi_*_minus (out):  components of grad(phi) in minus direction
c    phi (in):           phi 
c    D1 (in):            scratch space for holding undivided first-differences
c    dx (in):            grid spacing 
c    *_gb (in):          index range for ghostbox
c    *_fb (in):          index range for fillbox
c
c  NOTES:
c   - it is assumed that BOTH the plus AND minus derivatives have
c     the same fillbox
c
c***********************************************************************
      subroutine lsm1dHJENO1(
     &  phi_x_plus,
     &  ilo_grad_phi_plus_gb, ihi_grad_phi_plus_gb, 
     &  phi_x_minus,
     &  ilo_grad_phi_minus_gb, ihi_grad_phi_minus_gb, 
     &  phi,
     &  ilo_phi_gb, ihi_phi_gb,
     &  D1,
     &  ilo_D1_gb, ihi_D1_gb,
     &  ilo_fb, ihi_fb,
     &  dx)
c***********************************************************************
c { begin subroutine
      implicit none

c     _grad_phi_plus_gb refers to ghostbox for grad_phi plus data
c     _grad_phi_minus_gb refers to ghostbox for grad_phi minus data
c     _phi_gb refers to ghostbox for phi data
c     _fb refers to fill-box for grad_phi data
      integer ilo_grad_phi_plus_gb, ihi_grad_phi_plus_gb
      integer ilo_grad_phi_minus_gb, ihi_grad_phi_minus_gb
      integer ilo_phi_gb, ihi_phi_gb
      integer ilo_D1_gb, ihi_D1_gb
      integer ilo_fb, ihi_fb
      double precision phi_x_plus(
     &                    ilo_grad_phi_plus_gb:ihi_grad_phi_plus_gb)
      double precision phi_x_minus(
     &                    ilo_grad_phi_minus_gb:ihi_grad_phi_minus_gb)
      double precision phi(ilo_phi_gb:ihi_phi_gb)
      double precision D1(ilo_D1_gb:ihi_D1_gb)
      double precision dx, inv_dx
      integer i
      double precision zero
      parameter (zero=0.0d0)
      double precision zero_tol
      parameter (zero_tol=1.d-8)
      integer order
      parameter (order=1)


c     compute inv_dx
      inv_dx = 1.0d0/dx

c     compute first undivided differences (i.e. D1)
      call lsm1dComputeDn(D1, 
     &                    ilo_D1_gb, ihi_D1_gb, 
     &                    phi, 
     &                    ilo_phi_gb, ihi_phi_gb, 
     &                    ilo_fb, ihi_fb, 
     &                    order)

c----------------------------------------------------
c    compute phi_x_plus 
c----------------------------------------------------
c     { begin loop over grid 
      do i=ilo_fb,ihi_fb

        phi_x_plus(i) = D1(i+1)*inv_dx

      enddo
c     } end loop over grid 

c----------------------------------------------------
c    compute phi_x_minus
c----------------------------------------------------
c     { begin loop over grid 
      do i=ilo_fb,ihi_fb

        phi_x_minus(i) = D1(i)*inv_dx

      enddo
c     } end loop over grid 

      return
      end
c } end subroutine
c***********************************************************************

c***********************************************************************
c
c  lsm1dHJENO2() computes the forward (plus) and backward (minus)
c  second-order Hamilton-Jacobi ENO approximations to the gradient of
c  phi.
c
c  Arguments:
c    phi_*_plus (out):   components of grad(phi) in plus direction
c    phi_*_minus (out):  components of grad(phi) in minus direction
c    phi (in):           phi 
c    D1 (in):            scratch space for holding undivided first-differences
c    D2 (in):            scratch space for holding undivided second-differences
c    dx (in):            grid spacing 
c    *_gb (in):          index range for ghostbox
c    *_fb (in):          index range for fillbox
c
c  NOTES:
c   - it is assumed that BOTH the plus AND minus derivatives have
c     the same fillbox
c
c***********************************************************************
      subroutine lsm1dHJENO2(
     &  phi_x_plus,
     &  ilo_grad_phi_plus_gb, ihi_grad_phi_plus_gb, 
     &  phi_x_minus,
     &  ilo_grad_phi_minus_gb, ihi_grad_phi_minus_gb, 
     &  phi,
     &  ilo_phi_gb, ihi_phi_gb,
     &  D1,
     &  ilo_D1_gb, ihi_D1_gb,
     &  D2,
     &  ilo_D2_gb, ihi_D2_gb,
     &  ilo_fb, ihi_fb,
     &  dx)
c***********************************************************************
c { begin subroutine
      implicit none

c     _grad_phi_plus_gb refers to ghostbox for grad_phi plus data
c     _grad_phi_minus_gb refers to ghostbox for grad_phi minus data
c     _phi_gb refers to ghostbox for phi data
c     _fb refers to fill-box for grad_phi data
      integer ilo_grad_phi_plus_gb, ihi_grad_phi_plus_gb
      integer ilo_grad_phi_minus_gb, ihi_grad_phi_minus_gb
      integer ilo_phi_gb, ihi_phi_gb
      integer ilo_D1_gb, ihi_D1_gb
      integer ilo_D2_gb, ihi_D2_gb
      integer ilo_fb, ihi_fb
      double precision phi_x_plus(
     &                    ilo_grad_phi_plus_gb:ihi_grad_phi_plus_gb)
      double precision phi_x_minus(
     &                    ilo_grad_phi_minus_gb:ihi_grad_phi_minus_gb)
      double precision phi(ilo_phi_gb:ihi_phi_gb)
      double precision D1(ilo_D1_gb:ihi_D1_gb)
      double precision D2(ilo_D2_gb:ihi_D2_gb)
      double precision dx, inv_dx
      integer i
      double precision zero, half
      parameter (zero=0.0d0, half=0.5d0)
      double precision zero_tol
      parameter (zero_tol=1.d-8)
      integer order_1, order_2
      parameter (order_1=1,order_2=2)


c     compute inv_dx
      inv_dx = 1.0d0/dx

c     compute first undivided differences (i.e. D1) 
      call lsm1dComputeDn(D1, 
     &                    ilo_D1_gb, ihi_D1_gb, 
     &                    phi, 
     &                    ilo_phi_gb, ihi_phi_gb, 
     &                    ilo_fb-1, ihi_fb+1, 
     &                    order_1)

c     compute second undivided differences (i.e. D2)
      call lsm1dComputeDn(D2,
     &                    ilo_D2_gb, ihi_D2_gb, 
     &                    D1, 
     &                    ilo_D1_gb, ihi_D1_gb, 
     &                    ilo_fb-1, ihi_fb+1, 
     &                    order_2)

c----------------------------------------------------
c    compute phi_x_plus 
c----------------------------------------------------
c     { begin loop over grid 
      do i=ilo_fb,ihi_fb

        if (abs(D2(i)).lt.abs(D2(i+1))) then
          phi_x_plus(i) = (D1(i+1) - half*D2(i))*inv_dx
        else
          phi_x_plus(i) = (D1(i+1) - half*D2(i+1))*inv_dx
        endif

      enddo
c     } end loop over grid 

c----------------------------------------------------
c    compute phi_x_minus
c----------------------------------------------------
c     { begin loop over grid 
      do i=ilo_fb,ihi_fb

        if (abs(D2(i-1)).lt.abs(D2(i))) then
          phi_x_minus(i) = (D1(i) + half*D2(i-1))*inv_dx
        else
          phi_x_minus(i) = (D1(i) + half*D2(i))*inv_dx
        endif

      enddo
c     } end loop over grid 

      return
      end
c } end subroutine
c***********************************************************************

c***********************************************************************
c
c  lsm1dHJENO3() computes the forward (plus) and backward (minus)
c  third-order Hamilton-Jacobi ENO approximations to the gradient of
c  phi.
c
c  Arguments:
c    phi_*_plus (out):   components of grad(phi) in plus direction
c    phi_*_minus (out):  components of grad(phi) in minus direction
c    phi (in):           phi 
c    D1 (in):            scratch space for holding undivided first-differences
c    D2 (in):            scratch space for holding undivided second-differences
c    D3 (in):            scratch space for holding undivided third-differences
c    dx (in):            grid spacing 
c    *_gb (in):          index range for ghostbox
c    *_fb (in):          index range for fillbox
c
c  NOTES:
c   - it is assumed that BOTH the plus AND minus derivatives have
c     the same fillbox
c
c***********************************************************************
      subroutine lsm1dHJENO3(
     &  phi_x_plus,
     &  ilo_grad_phi_plus_gb, ihi_grad_phi_plus_gb, 
     &  phi_x_minus,
     &  ilo_grad_phi_minus_gb, ihi_grad_phi_minus_gb, 
     &  phi,
     &  ilo_phi_gb, ihi_phi_gb,
     &  D1,
     &  ilo_D1_gb, ihi_D1_gb,
     &  D2,
     &  ilo_D2_gb, ihi_D2_gb,
     &  D3,
     &  ilo_D3_gb, ihi_D3_gb,
     &  ilo_fb, ihi_fb,
     &  dx)
c***********************************************************************
c { begin subroutine
      implicit none

c     _grad_phi_plus_gb refers to ghostbox for grad_phi plus data
c     _grad_phi_minus_gb refers to ghostbox for grad_phi minus data
c     _phi_gb refers to ghostbox for phi data
c     _fb refers to fill-box for grad_phi data
      integer ilo_grad_phi_plus_gb, ihi_grad_phi_plus_gb
      integer ilo_grad_phi_minus_gb, ihi_grad_phi_minus_gb
      integer ilo_phi_gb, ihi_phi_gb
      integer ilo_D1_gb, ihi_D1_gb
      integer ilo_D2_gb, ihi_D2_gb
      integer ilo_D3_gb, ihi_D3_gb
      integer ilo_fb, ihi_fb
      double precision phi_x_plus(
     &                    ilo_grad_phi_plus_gb:ihi_grad_phi_plus_gb)
      double precision phi_x_minus(
     &                    ilo_grad_phi_minus_gb:ihi_grad_phi_minus_gb)
      double precision phi(ilo_phi_gb:ihi_phi_gb)
      double precision D1(ilo_D1_gb:ihi_D1_gb)
      double precision D2(ilo_D2_gb:ihi_D2_gb)
      double precision D3(ilo_D3_gb:ihi_D3_gb)
      double precision dx, inv_dx
      integer i
      double precision zero, half, third, sixth
      parameter (zero=0.0d0, half=0.5d0, third=1.d0/3.d0)
      parameter (sixth=1.d0/6.d0)
      double precision zero_tol
      parameter (zero_tol=1.d-8)
      integer order_1, order_2, order_3
      parameter (order_1=1,order_2=2,order_3=3)


c     compute inv_dx
      inv_dx = 1.0d0/dx

c     compute first undivided differences (i.e. D1)
      call lsm1dComputeDn(D1, 
     &                    ilo_D1_gb, ihi_D1_gb, 
     &                    phi, 
     &                    ilo_phi_gb, ihi_phi_gb, 
     &                    ilo_fb-2, ihi_fb+2, 
     &                    order_1)

c     compute second undivided differences (i.e. D2)
      call lsm1dComputeDn(D2,
     &                    ilo_D2_gb, ihi_D2_gb, 
     &                    D1, 
     &                    ilo_D1_gb, ihi_D1_gb, 
     &                    ilo_fb-2, ihi_fb+2, 
     &                    order_2)

c     compute third undivided differences (i.e. D3)
      call lsm1dComputeDn(D3,
     &                    ilo_D3_gb, ihi_D3_gb, 
     &                    D2, 
     &                    ilo_D2_gb, ihi_D2_gb, 
     &                    ilo_fb-1, ihi_fb+1, 
     &                    order_3)

c----------------------------------------------------
c    compute phi_x_plus
c----------------------------------------------------
c     { begin loop over grid 
      do i=ilo_fb,ihi_fb

        phi_x_plus(i) = D1(i+1)
        if (abs(D2(i)).lt.abs(D2(i+1))) then
          phi_x_plus(i) = phi_x_plus(i) - half*D2(i) 
          if (abs(D3(i)).lt.abs(D3(i+1))) then
            phi_x_plus(i) = phi_x_plus(i) - sixth*D3(i)
          else
            phi_x_plus(i) = phi_x_plus(i) - sixth*D3(i+1)
          endif
        else
          phi_x_plus(i) = phi_x_plus(i) - half*D2(i+1) 
          if (abs(D3(i+1)).lt.abs(D3(i+2))) then
            phi_x_plus(i) = phi_x_plus(i) + third*D3(i+1)
          else
            phi_x_plus(i) = phi_x_plus(i) + third*D3(i+2)
          endif
        endif

c       divide phi_x_plus by dx
        phi_x_plus(i) = phi_x_plus(i)*inv_dx

      enddo
c     } end loop over grid 

c----------------------------------------------------
c    compute phi_x_minus
c----------------------------------------------------
c     { begin loop over grid 
      do i=ilo_fb,ihi_fb

        phi_x_minus(i) = D1(i)
        if (abs(D2(i-1)).lt.abs(D2(i))) then
          phi_x_minus(i) = phi_x_minus(i) + half*D2(i-1) 
          if (abs(D3(i-1)).lt.abs(D3(i))) then
            phi_x_minus(i) = phi_x_minus(i) + third*D3(i-1)
          else
            phi_x_minus(i) = phi_x_minus(i) + third*D3(i)
          endif
        else
          phi_x_minus(i) = phi_x_minus(i) + half*D2(i) 
          if (abs(D3(i)).lt.abs(D3(i+1))) then
            phi_x_minus(i) = phi_x_minus(i) - sixth*D3(i)
          else
            phi_x_minus(i) = phi_x_minus(i) - sixth*D3(i+1)
          endif
        endif

c       divide phi_x_minus by dx
        phi_x_minus(i) = phi_x_minus(i)*inv_dx

      enddo
c     } end loop over grid 

      return
      end
c } end subroutine
c***********************************************************************

c***********************************************************************
c
c  lsm1dHJWENO5() computes the forward (plus) and backward (minus)
c  fifth-order Hamilton-Jacobi WENO approximations to the gradient of
c  phi.
c
c  Arguments:
c    phi_*_plus (out):   components of grad(phi) in plus direction
c    phi_*_minus (out):  components of grad(phi) in minus direction
c    phi (in):           phi 
c    D1 (in):            scratch space for holding undivided first-differences
c    dx (in):            grid spacing 
c    *_gb (in):          index range for ghostbox
c    *_fb (in):          index range for fillbox
c
c  NOTES:
c   - it is assumed that BOTH the plus AND minus derivatives have
c     the same fillbox
c
c***********************************************************************
      subroutine lsm1dHJWENO5(
     &  phi_x_plus,
     &  ilo_grad_phi_plus_gb, ihi_grad_phi_plus_gb, 
     &  phi_x_minus,
     &  ilo_grad_phi_minus_gb, ihi_grad_phi_minus_gb, 
     &  phi,
     &  ilo_phi_gb, ihi_phi_gb,
     &  D1,
     &  ilo_D1_gb, ihi_D1_gb,
     &  ilo_fb, ihi_fb,
     &  dx)
c***********************************************************************
c { begin subroutine
      implicit none

c     _grad_phi_plus_gb refers to ghostbox for grad_phi plus data
c     _grad_phi_minus_gb refers to ghostbox for grad_phi minus data
c     _phi_gb refers to ghostbox for phi data
c     _fb refers to fill-box for grad_phi data
      integer ilo_grad_phi_plus_gb, ihi_grad_phi_plus_gb
      integer ilo_grad_phi_minus_gb, ihi_grad_phi_minus_gb
      integer ilo_phi_gb, ihi_phi_gb
      integer ilo_D1_gb, ihi_D1_gb
      integer ilo_fb, ihi_fb
      double precision phi_x_plus(
     &                    ilo_grad_phi_plus_gb:ihi_grad_phi_plus_gb)
      double precision phi_x_minus(
     &                    ilo_grad_phi_minus_gb:ihi_grad_phi_minus_gb)
      double precision phi(ilo_phi_gb:ihi_phi_gb)
      double precision D1(ilo_D1_gb:ihi_D1_gb)
      double precision dx, inv_dx

c     variables for WENO calculation 
      double precision v1,v2,v3,v4,v5
      double precision S1,S2,S3
      double precision a1,a2,a3, inv_sum_a
      double precision phi_x_1,phi_x_2,phi_x_3
      double precision tiny_nonzero_number
      parameter (tiny_nonzero_number=1.d-99)
      double precision eps
      double precision one_third, seven_sixths, eleven_sixths
      double precision one_sixth, five_sixths
      double precision thirteen_twelfths, one_fourth
      parameter (one_third=1.d0/3.d0)
      parameter (seven_sixths=7.d0/6.d0)
      parameter (eleven_sixths=11.d0/6.d0) 
      parameter (one_sixth=1.d0/6.d0)
      parameter (five_sixths=5.d0/6.d0)
      parameter (thirteen_twelfths=13.d0/12.d0)
      parameter (one_fourth=0.25d0)

      integer i
      double precision zero
      parameter (zero=0.0d0)
      double precision zero_tol
      parameter (zero_tol=1.d-8)
      integer order_1
      parameter (order_1=1)


c     compute inv_dx
      inv_dx = 1.0d0/dx

c     compute first undivided differences (i.e. D1)
      call lsm1dComputeDn(D1, 
     &                    ilo_D1_gb, ihi_D1_gb, 
     &                    phi, 
     &                    ilo_phi_gb, ihi_phi_gb, 
     &                    ilo_fb-2, ihi_fb+2, 
     &                    order_1)

c----------------------------------------------------
c    compute phi_x_plus
c----------------------------------------------------
c     { begin loop over grid 
      do i=ilo_fb,ihi_fb

c       extract v1,v2,v3,v4,v5 from D1
        v1 = D1(i+3)*inv_dx
        v2 = D1(i+2)*inv_dx
        v3 = D1(i+1)*inv_dx
        v4 = D1(i)*inv_dx
        v5 = D1(i-1)*inv_dx

c       WENO5 algorithm for current grid point using appropriate
c       upwind values for v1,...,v5

c       compute eps for current grid point
        eps = 1e-6*max(v1*v1,v2*v2,v3*v3,v4*v4,v5*v5)
     &      + tiny_nonzero_number

c       compute the phi_x_1, phi_x_2, phi_x_3
        phi_x_1 = one_third*v1 - seven_sixths*v2 + eleven_sixths*v3
        phi_x_2 = -one_sixth*v2 + five_sixths*v3 + one_third*v4
        phi_x_3 = one_third*v3 + five_sixths*v4 - one_sixth*v5

c       compute the smoothness measures
        S1 = thirteen_twelfths*(v1-2.d0*v2+v3)**2
     &     + one_fourth*(v1-4.d0*v2+3.d0*v3)**2
        S2 = thirteen_twelfths*(v2-2.d0*v3+v4)**2
     &     + one_fourth*(v2-v4)**2
        S3 = thirteen_twelfths*(v3-2.d0*v4+v5)**2
     &     + one_fourth*(3.d0*v3-4.d0*v4+v5)**2

c       compute normalized weights
        a1 = 0.1d0/(S1+eps)**2
        a2 = 0.6d0/(S2+eps)**2
        a3 = 0.3d0/(S3+eps)**2
        inv_sum_a = 1.0d0 / (a1 + a2 + a3)
        a1 = a1*inv_sum_a
        a2 = a2*inv_sum_a
        a3 = a3*inv_sum_a

c       compute phi_x_plus 
        phi_x_plus(i) = a1*phi_x_1 + a2*phi_x_2 + a3*phi_x_3

      enddo
c     } end loop over grid 

c----------------------------------------------------
c    compute phi_x_minus
c----------------------------------------------------
c     { begin loop over grid 
      do i=ilo_fb,ihi_fb

c       extract v1,v2,v3,v4,v5 from D1
        v1 = D1(i-2)*inv_dx
        v2 = D1(i-1)*inv_dx
        v3 = D1(i)*inv_dx
        v4 = D1(i+1)*inv_dx
        v5 = D1(i+2)*inv_dx

c       WENO5 algorithm for current grid point using appropriate
c       upwind values for v1,...,v5

c       compute eps for current grid point
        eps = 1e-6*max(v1*v1,v2*v2,v3*v3,v4*v4,v5*v5)
     &      + tiny_nonzero_number

c       compute the phi_x_1, phi_x_2, phi_x_3
        phi_x_1 = one_third*v1 - seven_sixths*v2 + eleven_sixths*v3
        phi_x_2 = -one_sixth*v2 + five_sixths*v3 + one_third*v4
        phi_x_3 = one_third*v3 + five_sixths*v4 - one_sixth*v5

c       compute the smoothness measures
        S1 = thirteen_twelfths*(v1-2.d0*v2+v3)**2
     &     + one_fourth*(v1-4.d0*v2+3.d0*v3)**2
        S2 = thirteen_twelfths*(v2-2.d0*v3+v4)**2
     &     + one_fourth*(v2-v4)**2
        S3 = thirteen_twelfths*(v3-2.d0*v4+v5)**2
     &     + one_fourth*(3.d0*v3-4.d0*v4+v5)**2

c       compute normalized weights
        a1 = 0.1d0/(S1+eps)**2
        a2 = 0.6d0/(S2+eps)**2
        a3 = 0.3d0/(S3+eps)**2
        inv_sum_a = 1.0d0 / (a1 + a2 + a3)
        a1 = a1*inv_sum_a
        a2 = a2*inv_sum_a
        a3 = a3*inv_sum_a

c       compute phi_x_minus 
        phi_x_minus(i) = a1*phi_x_1 + a2*phi_x_2 + a3*phi_x_3

      enddo
c     } end loop over grid 

      return
      end
c } end subroutine
c***********************************************************************

c***********************************************************************
c
c  lsm1dUpwindHJENO1() computes the first-order Hamilton-Jacobi ENO 
c  upwind approximation to the gradient of phi.
c
c  Arguments:
c    phi_x (out):  derivative of phi
c    phi (in):     phi
c    vel_x (in):   velocity in the x-direction
c    D1 (in):      scratch space for holding undivided first-differences
c    dx (in):      grid cell size
c    *_gb (in):    index range for ghostbox
c    *_fb (in):    index range for fillbox
c
c***********************************************************************
      subroutine lsm1dUpwindHJENO1(
     &  phi_x,
     &  ilo_grad_phi_gb, ihi_grad_phi_gb, 
     &  phi,
     &  ilo_phi_gb, ihi_phi_gb,
     &  vel_x,
     &  ilo_vel_gb, ihi_vel_gb,
     &  D1,
     &  ilo_D1_gb, ihi_D1_gb,
     &  ilo_fb, ihi_fb,
     &  dx)
c***********************************************************************
c { begin subroutine
      implicit none

c     _grad_phi_gb refers to ghostbox for grad_phi data
c     _phi_gb refers to ghostbox for phi data
c     _vel_gb refers to ghostbox for velocity data
c     _fb refers to fill-box for grad_phi data
      integer ilo_grad_phi_gb, ihi_grad_phi_gb
      integer ilo_phi_gb, ihi_phi_gb
      integer ilo_vel_gb, ihi_vel_gb
      integer ilo_D1_gb, ihi_D1_gb
      integer ilo_fb, ihi_fb
      double precision phi_x(ilo_grad_phi_gb:ihi_grad_phi_gb)
      double precision phi(ilo_phi_gb:ihi_phi_gb)
      double precision vel_x(ilo_vel_gb:ihi_vel_gb)
      double precision D1(ilo_D1_gb:ihi_D1_gb)
      double precision dx, inv_dx
      integer i
      double precision zero
      parameter (zero=0.0d0)
      double precision zero_tol
      parameter (zero_tol=1.d-8)
      integer order
      parameter (order=1)


c     compute inv_dx
      inv_dx = 1.0d0/dx

c     compute first undivided differences (i.e. D1)
      call lsm1dComputeDn(D1, 
     &                    ilo_D1_gb, ihi_D1_gb, 
     &                    phi, 
     &                    ilo_phi_gb, ihi_phi_gb, 
     &                    ilo_fb, ihi_fb, 
     &                    order)

c----------------------------------------------------
c    compute upwind phi_x 
c----------------------------------------------------
c     { begin loop over grid 
      do i=ilo_fb,ihi_fb

c       phi_x
        if (abs(vel_x(i)) .lt. zero_tol) then
c         vel_x == 0
          phi_x(i) = zero
        elseif (vel_x(i) .gt. 0) then
c         vel_x > 0
          phi_x(i) = D1(i)*inv_dx
        else
c         vel_x < 0
          phi_x(i) = D1(i+1)*inv_dx
        endif

      enddo
c     } end loop over grid 

      return
      end
c } end subroutine
c***********************************************************************

c***********************************************************************
c
c  lsm1dUpwindHJENO2() computes the second-order Hamilton-Jacobi ENO 
c  upwind approximation to the gradient of phi.
c
c  Arguments:
c    phi_x (out):  derivative of phi
c    phi (in):     phi
c    vel_x (in):   velocity in the x-direction
c    D1 (in):      scratch space for holding undivided first-differences
c    D2 (in):      scratch space for holding undivided second-differences
c    dx (in):      grid cell size
c    *_gb (in):    index range for ghostbox
c    *_fb (in):    index range for fillbox
c
c***********************************************************************
      subroutine lsm1dUpwindHJENO2(
     &  phi_x,
     &  ilo_grad_phi_gb, ihi_grad_phi_gb, 
     &  phi,
     &  ilo_phi_gb, ihi_phi_gb,
     &  vel_x,
     &  ilo_vel_gb, ihi_vel_gb,
     &  D1,
     &  ilo_D1_gb, ihi_D1_gb,
     &  D2,
     &  ilo_D2_gb, ihi_D2_gb,
     &  ilo_fb, ihi_fb,
     &  dx)
c***********************************************************************
c { begin subroutine
      implicit none

c     _grad_phi_gb refers to ghostbox for grad_phi data
c     _phi_gb refers to ghostbox for phi data
c     _vel_gb refers to ghostbox for velocity data
c     _fb refers to fill-box for grad_phi data
      integer ilo_grad_phi_gb, ihi_grad_phi_gb
      integer ilo_phi_gb, ihi_phi_gb
      integer ilo_vel_gb, ihi_vel_gb
      integer ilo_D1_gb, ihi_D1_gb
      integer ilo_D2_gb, ihi_D2_gb
      integer ilo_fb, ihi_fb
      double precision phi_x(ilo_grad_phi_gb:ihi_grad_phi_gb)
      double precision phi(ilo_phi_gb:ihi_phi_gb)
      double precision vel_x(ilo_vel_gb:ihi_vel_gb)
      double precision D1(ilo_D1_gb:ihi_D1_gb)
      double precision D2(ilo_D2_gb:ihi_D2_gb)
      double precision dx, inv_dx
      integer i
      double precision zero, half
      parameter (zero=0.0d0, half=0.5d0)
      double precision zero_tol
      parameter (zero_tol=1.d-8)
      integer order_1, order_2
      parameter (order_1=1,order_2=2)


c     compute inv_dx
      inv_dx = 1.0d0/dx

c     compute first undivided differences (i.e. D1) 
      call lsm1dComputeDn(D1, 
     &                    ilo_D1_gb, ihi_D1_gb, 
     &                    phi, 
     &                    ilo_phi_gb, ihi_phi_gb, 
     &                    ilo_fb-1, ihi_fb+1, 
     &                    order_1)

c     compute second undivided differences (i.e. D2)
      call lsm1dComputeDn(D2,
     &                    ilo_D2_gb, ihi_D2_gb, 
     &                    D1, 
     &                    ilo_D1_gb, ihi_D1_gb, 
     &                    ilo_fb-1, ihi_fb+1, 
     &                    order_2)

c----------------------------------------------------
c    compute upwind phi_x 
c----------------------------------------------------
c     { begin loop over grid 
      do i=ilo_fb,ihi_fb

        if (abs(vel_x(i)) .lt. zero_tol) then

c         vel_x == 0
          phi_x(i) = zero

        elseif (vel_x(i) .gt. 0) then

c         vel_x > 0
          if (abs(D2(i-1)).lt.abs(D2(i))) then
            phi_x(i) = (D1(i) + half*D2(i-1))*inv_dx
          else
            phi_x(i) = (D1(i) + half*D2(i))*inv_dx
          endif

        else

c         vel_x < 0
          if (abs(D2(i)).lt.abs(D2(i+1))) then
            phi_x(i) = (D1(i+1) - half*D2(i))*inv_dx
          else
            phi_x(i) = (D1(i+1) - half*D2(i+1))*inv_dx
          endif

        endif

      enddo
c     } end loop over grid 

      return
      end
c } end subroutine
c***********************************************************************

c***********************************************************************
c
c  lsm1dUpwindHJENO3() computes the third-order Hamilton-Jacobi ENO 
c  upwind approximation to the gradient of phi.
c
c  Arguments:
c    phi_x (out):  derivative of phi
c    phi (in):     phi
c    vel_x (in):   velocity in the x-direction
c    D1 (in):      scratch space for holding undivided first-differences
c    D2 (in):      scratch space for holding undivided second-differences
c    D3 (in):      scratch space for holding undivided third-differences
c    dx (in):      grid cell size
c    *_gb (in):    index range for ghostbox
c    *_fb (in):    index range for fillbox
c
c***********************************************************************
      subroutine lsm1dUpwindHJENO3(
     &  phi_x,
     &  ilo_grad_phi_gb, ihi_grad_phi_gb, 
     &  phi,
     &  ilo_phi_gb, ihi_phi_gb,
     &  vel_x, 
     &  ilo_vel_gb, ihi_vel_gb, 
     &  D1,
     &  ilo_D1_gb, ihi_D1_gb,
     &  D2,
     &  ilo_D2_gb, ihi_D2_gb,
     &  D3,
     &  ilo_D3_gb, ihi_D3_gb,
     &  ilo_fb, ihi_fb, 
     &  dx)
c***********************************************************************
c { begin subroutine
      implicit none

c     _grad_phi_gb refers to ghostbox for grad_phi data
c     _phi_gb refers to ghostbox for phi data
c     _vel_gb refers to ghostbox for velocity data
c     _fb refers to fill-box for grad_phi data
      integer ilo_grad_phi_gb, ihi_grad_phi_gb
      integer ilo_phi_gb, ihi_phi_gb
      integer ilo_vel_gb, ihi_vel_gb
      integer ilo_D1_gb, ihi_D1_gb
      integer ilo_D2_gb, ihi_D2_gb
      integer ilo_D3_gb, ihi_D3_gb
      integer ilo_fb, ihi_fb
      double precision phi_x(ilo_grad_phi_gb:ihi_grad_phi_gb)
      double precision phi(ilo_phi_gb:ihi_phi_gb)
      double precision vel_x(ilo_vel_gb:ihi_vel_gb)
      double precision D1(ilo_D1_gb:ihi_D1_gb)
      double precision D2(ilo_D2_gb:ihi_D2_gb)
      double precision D3(ilo_D3_gb:ihi_D3_gb)
      double precision dx, inv_dx
      integer i
      double precision zero, half, third, sixth
      parameter (zero=0.0d0, half=0.5d0, third=1.d0/3.d0)
      parameter (sixth=1.d0/6.d0)
      double precision zero_tol
      parameter (zero_tol=1.d-8)
      integer order_1, order_2, order_3
      parameter (order_1=1,order_2=2,order_3=3)


c     compute inv_dx
      inv_dx = 1.0d0/dx

c     compute first undivided differences (i.e. D1)
      call lsm1dComputeDn(D1, 
     &                    ilo_D1_gb, ihi_D1_gb, 
     &                    phi, 
     &                    ilo_phi_gb, ihi_phi_gb, 
     &                    ilo_fb-2, ihi_fb+2, 
     &                    order_1)

c     compute second undivided differences (i.e. D2)
      call lsm1dComputeDn(D2,
     &                    ilo_D2_gb, ihi_D2_gb, 
     &                    D1, 
     &                    ilo_D1_gb, ihi_D1_gb, 
     &                    ilo_fb-2, ihi_fb+2, 
     &                    order_2)

c     compute third undivided differences (i.e. D3)
      call lsm1dComputeDn(D3,
     &                    ilo_D3_gb, ihi_D3_gb, 
     &                    D2, 
     &                    ilo_D2_gb, ihi_D2_gb, 
     &                    ilo_fb-1, ihi_fb+1, 
     &                    order_3)

c----------------------------------------------------
c    compute upwind phi_x
c----------------------------------------------------
c     { begin loop over grid 
      do i=ilo_fb,ihi_fb

c       phi_x
        if (abs(vel_x(i)) .lt. zero_tol) then

c         vel_x == 0
          phi_x(i) = zero

        elseif (vel_x(i) .gt. 0) then

c         vel_x > 0
          phi_x(i) = D1(i)
          if (abs(D2(i-1)).lt.abs(D2(i))) then
            phi_x(i) = phi_x(i) + half*D2(i-1) 
            if (abs(D3(i-1)).lt.abs(D3(i))) then
              phi_x(i) = phi_x(i) + third*D3(i-1)
            else
              phi_x(i) = phi_x(i) + third*D3(i)
            endif
          else
            phi_x(i) = phi_x(i) + half*D2(i) 
            if (abs(D3(i)).lt.abs(D3(i+1))) then
              phi_x(i) = phi_x(i) - sixth*D3(i)
            else
              phi_x(i) = phi_x(i) - sixth*D3(i+1)
            endif
          endif

        else

c         vel_x < 0
          phi_x(i) = D1(i+1)
          if (abs(D2(i)).lt.abs(D2(i+1))) then
            phi_x(i) = phi_x(i) - half*D2(i) 
            if (abs(D3(i)).lt.abs(D3(i+1))) then
              phi_x(i) = phi_x(i) - sixth*D3(i)
            else
              phi_x(i) = phi_x(i) - sixth*D3(i+1)
            endif
          else
            phi_x(i) = phi_x(i) - half*D2(i+1) 
            if (abs(D3(i+1)).lt.abs(D3(i+2))) then
              phi_x(i) = phi_x(i) + third*D3(i+1)
            else
              phi_x(i) = phi_x(i) + third*D3(i+2)
            endif
          endif

        endif

c       divide phi_x by dx
        phi_x(i) = phi_x(i)*inv_dx

      enddo
c     } end loop over grid 

      return
      end
c } end subroutine
c***********************************************************************

c***********************************************************************
c
c  lsm1dUpwindHJWENO5() computes the fifth-order Hamilton-Jacobi WENO 
c  upwind approximation to the gradient of phi.  
c
c  Arguments:
c    phi_x (out):  derivative of phi
c    phi (in):     phi
c    vel_x (in):   velocity in the x-direction
c    D1 (in):      scratch space for holding undivided first-differences
c    dx (in):      grid cell size
c    *_gb (in):    index range for ghostbox
c    *_fb (in):    index range for fillbox
c
c***********************************************************************
      subroutine lsm1dUpwindHJWENO5(
     &  phi_x,
     &  ilo_grad_phi_gb, ihi_grad_phi_gb, 
     &  phi,
     &  ilo_phi_gb, ihi_phi_gb,
     &  vel_x, 
     &  ilo_vel_gb, ihi_vel_gb, 
     &  D1,
     &  ilo_D1_gb, ihi_D1_gb,
     &  ilo_fb, ihi_fb, 
     &  dx)
c***********************************************************************
c { begin subroutine
      implicit none

c     _grad_phi_gb refers to ghostbox for grad_phi data
c     _phi_gb refers to ghostbox for phi data
c     _vel_gb refers to ghostbox for velocity data
c     _fb refers to fill-box for grad_phi data
      integer ilo_grad_phi_gb, ihi_grad_phi_gb
      integer ilo_phi_gb, ihi_phi_gb
      integer ilo_vel_gb, ihi_vel_gb
      integer ilo_D1_gb, ihi_D1_gb
      integer ilo_fb, ihi_fb
      double precision phi_x(ilo_grad_phi_gb:ihi_grad_phi_gb)
      double precision phi(ilo_phi_gb:ihi_phi_gb)
      double precision vel_x(ilo_vel_gb:ihi_vel_gb)
      double precision D1(ilo_D1_gb:ihi_D1_gb)
      double precision dx, inv_dx

c     variables for WENO calculation 
      double precision v1,v2,v3,v4,v5
      double precision S1,S2,S3
      double precision a1,a2,a3, inv_sum_a
      double precision phi_x_1,phi_x_2,phi_x_3
      double precision tiny_nonzero_number
      parameter (tiny_nonzero_number=1.d-99)
      double precision eps
      double precision one_third, seven_sixths, eleven_sixths
      double precision one_sixth, five_sixths
      double precision thirteen_twelfths, one_fourth
      parameter (one_third=1.d0/3.d0)
      parameter (seven_sixths=7.d0/6.d0)
      parameter (eleven_sixths=11.d0/6.d0) 
      parameter (one_sixth=1.d0/6.d0)
      parameter (five_sixths=5.d0/6.d0)
      parameter (thirteen_twelfths=13.d0/12.d0)
      parameter (one_fourth=0.25d0)

      integer i
      double precision zero
      parameter (zero=0.0d0)
      double precision zero_tol
      parameter (zero_tol=1.d-8)
      integer order_1
      parameter (order_1=1)


c     compute inv_dx
      inv_dx = 1.0d0/dx

c     compute first undivided differences (i.e. D1)
      call lsm1dComputeDn(D1, 
     &                    ilo_D1_gb, ihi_D1_gb, 
     &                    phi, 
     &                    ilo_phi_gb, ihi_phi_gb, 
     &                    ilo_fb-2, ihi_fb+2, 
     &                    order_1)

c----------------------------------------------------
c    compute upwind phi_x
c----------------------------------------------------
c     { begin loop over grid 
      do i=ilo_fb,ihi_fb

c       { begin upwind cases
        if (abs(vel_x(i)) .lt. zero_tol) then
          phi_x(i) = zero
        else
          if (vel_x(i) .gt. 0) then

c           extract v1,v2,v3,v4,v5 from D1
            v1 = D1(i-2)*inv_dx
            v2 = D1(i-1)*inv_dx
            v3 = D1(i)*inv_dx
            v4 = D1(i+1)*inv_dx
            v5 = D1(i+2)*inv_dx

          else 

c           extract v1,v2,v3,v4,v5 from D1
            v1 = D1(i+3)*inv_dx
            v2 = D1(i+2)*inv_dx
            v3 = D1(i+1)*inv_dx
            v4 = D1(i)*inv_dx
            v5 = D1(i-1)*inv_dx

          endif

c         WENO5 algorithm for current grid point using appropriate
c         upwind values for v1,...,v5

c         compute eps for current grid point
          eps = 1e-6*max(v1*v1,v2*v2,v3*v3,v4*v4,v5*v5)
     &        + tiny_nonzero_number

c         compute the phi_x_1, phi_x_2, phi_x_3
          phi_x_1 = one_third*v1 - seven_sixths*v2 + eleven_sixths*v3
          phi_x_2 = -one_sixth*v2 + five_sixths*v3 + one_third*v4
          phi_x_3 = one_third*v3 + five_sixths*v4 - one_sixth*v5

c         compute the smoothness measures
          S1 = thirteen_twelfths*(v1-2.d0*v2+v3)**2
     &       + one_fourth*(v1-4.d0*v2+3.d0*v3)**2
          S2 = thirteen_twelfths*(v2-2.d0*v3+v4)**2
     &       + one_fourth*(v2-v4)**2
          S3 = thirteen_twelfths*(v3-2.d0*v4+v5)**2
     &       + one_fourth*(3.d0*v3-4.d0*v4+v5)**2

c         compute normalized weights
          a1 = 0.1d0/(S1+eps)**2
          a2 = 0.6d0/(S2+eps)**2
          a3 = 0.3d0/(S3+eps)**2
          inv_sum_a = 1.0d0 / (a1 + a2 + a3)
          a1 = a1*inv_sum_a
          a2 = a2*inv_sum_a
          a3 = a3*inv_sum_a

c         compute phi_x 
          phi_x(i) = a1*phi_x_1 + a2*phi_x_2 + a3*phi_x_3

        endif
c       } end upwind cases


      enddo
c     } end loop over grid 

      return
      end
c } end subroutine
c***********************************************************************

c***********************************************************************
c
c  lsm1dCentralGradOrder2() computes the second-order, central,
c  finite difference approximation to the gradient of phi.
c
c  Arguments:
c    phi_* (out):  components of grad(phi) 
c    phi (in):     phi
c    dx (in):      grid spacing
c    *_gb (in):    index range for ghostbox
c    *_fb (in):    index range for fillbox
c
c***********************************************************************
      subroutine lsm1dCentralGradOrder2(
     &  phi_x, 
     &  ilo_grad_phi_gb, ihi_grad_phi_gb, 
     &  phi,
     &  ilo_phi_gb, ihi_phi_gb, 
     &  ilo_fb, ihi_fb,
     &  dx)
c***********************************************************************
c { begin subroutine
      implicit none

c     _grad_phi_gb refers to ghostbox for grad_phi data
c     _phi_gb refers to ghostbox for phi data
c     _fb refers to fill-box for grad_phi data
      integer ilo_grad_phi_gb, ihi_grad_phi_gb
      integer ilo_phi_gb, ihi_phi_gb
      integer ilo_fb, ihi_fb
      double precision phi_x(ilo_grad_phi_gb:ihi_grad_phi_gb)
      double precision phi(ilo_phi_gb:ihi_phi_gb)
      double precision dx
      integer i
      double precision dx_factor

c     compute denominator values
      dx_factor = 0.5d0/dx

c     { begin loop over grid 
      do i=ilo_fb,ihi_fb

        phi_x(i) = (phi(i+1) - phi(i-1))*dx_factor

      enddo
c     } end loop over grid 

      return
      end
c } end subroutine
c***********************************************************************

c***********************************************************************
c
c  lsm1dCentralGradOrder4() computes the second-order central 
c  finite difference approximation to the gradient of phi.
c
c  Arguments:
c    phi_* (out):  components of grad(phi) 
c    phi (in):     phi
c    dx (in):      grid spacing
c    *_gb (in):    index range for ghostbox
c    *_fb (in):    index range for fillbox
c
c***********************************************************************
      subroutine lsm1dCentralGradOrder4(
     &  phi_x,
     &  ilo_grad_phi_gb, ihi_grad_phi_gb, 
     &  phi,
     &  ilo_phi_gb, ihi_phi_gb, 
     &  ilo_fb, ihi_fb,
     &  dx)
c***********************************************************************
c { begin subroutine
      implicit none

c     _grad_phi_gb refers to ghostbox for grad_phi data
c     _phi_gb refers to ghostbox for phi data
c     _fb refers to fill-box for grad_phi data
      integer ilo_grad_phi_gb, ihi_grad_phi_gb
      integer ilo_phi_gb, ihi_phi_gb
      integer ilo_fb, ihi_fb
      double precision phi_x(ilo_grad_phi_gb:ihi_grad_phi_gb)
      double precision phi(ilo_phi_gb:ihi_phi_gb)
      double precision dx
      integer i
      double precision dx_factor
      double precision eight
      parameter (eight = 8.0d0)

c     compute denominator values
      dx_factor = 0.0833333333333333333333d0/dx

c     { begin loop over grid 
      do i=ilo_fb,ihi_fb

        phi_x(i) = ( -phi(i+2) + eight*phi(i+1) 
     &               +phi(i-2) - eight*phi(i-1) ) * dx_factor
   
      enddo
c     } end loop over grid 

      return
      end
c } end subroutine
c***********************************************************************

c***********************************************************************
c
c  lsm1dLaplacianOrder2() computes the second-order, central, 
c  finite difference approximation to the Laplacian of phi.
c
c  Arguments:
c    laplacian_phi (out):  Laplacian of phi
c    phi (in):             phi
c    dx (in):              grid spacing
c    *_gb (in):            index range for ghostbox
c    *_fb (in):            index range for fillbox
c
c***********************************************************************
      subroutine lsm1dLaplacianOrder2(
     &  laplacian_phi,
     &  ilo_laplacian_phi_gb, ihi_laplacian_phi_gb, 
     &  phi,
     &  ilo_phi_gb, ihi_phi_gb, 
     &  ilo_fb, ihi_fb,
     &  dx)
c***********************************************************************
c { begin subroutine
      implicit none

c     _laplacian_phi_gb refers to ghostbox for laplacian_phi data
c     _phi_gb refers to ghostbox for phi data
c     _fb refers to fill-box for grad_phi data
      integer ilo_laplacian_phi_gb, ihi_laplacian_phi_gb
      integer ilo_phi_gb, ihi_phi_gb
      integer ilo_fb, ihi_fb
      double precision laplacian_phi(
     &                   ilo_laplacian_phi_gb:ihi_laplacian_phi_gb)
      double precision phi(ilo_phi_gb:ihi_phi_gb)
      double precision dx
      integer i
      double precision inv_dx_sq

c     compute denominator values
      inv_dx_sq = 1.0d0/dx/dx

c     { begin loop over grid 
      do i=ilo_fb,ihi_fb

        laplacian_phi(i) = 
     &    inv_dx_sq * ( phi(i+1) - 2.0d0*phi(i) + phi(i-1) ) 
   
      enddo
c     } end loop over grid 

      return
      end
c } end subroutine
c***********************************************************************

c***********************************************************************
c
c  lsm1dPhiUpwindGradF() computes the "phi-upwind" gradient of a 
c  function, F, using the following "upwinding" scheme to compute 
c  the normal:
c
c    if phi > 0:  upwind direction is direction where phi is smaller
c
c    if phi < 0:  upwind direction is direction where phi is larger
c
c  Arguments:
c    F_* (out):       components of phi-upwinded grad(F)
c    F_*_plus (in):   components of grad(F) in plus direction
c    F_*_minus (in):  components of grad(F) in minus direction
c    phi (in):        level set function
c    dx (in):         grid spacing
c    *_gb (in):       index range for ghostbox
c    *_fb (in):       index range for fillbox
c
c  NOTES:
c   - phi is REQUIRED to have at least one ghost cell in each 
c     coordinate direction for upwinding
c
c***********************************************************************
      subroutine lsm1dPhiUpwindGradF(
     &  F_x, 
     &  ilo_grad_F_gb, ihi_grad_F_gb,
     &  F_x_plus,
     &  ilo_grad_F_plus_gb, ihi_grad_F_plus_gb,
     &  F_x_minus,
     &  ilo_grad_F_minus_gb, ihi_grad_F_minus_gb,
     &  phi,
     &  ilo_phi_gb, ihi_phi_gb,
     &  ilo_fb, ihi_fb)
c***********************************************************************
c { begin subroutine
      implicit none

c     _gb refers to ghostbox 
c     _fb refers to fill-box

      integer ilo_grad_F_gb, ihi_grad_F_gb
      integer ilo_grad_F_plus_gb, ihi_grad_F_plus_gb
      integer ilo_grad_F_minus_gb, ihi_grad_F_minus_gb
      integer ilo_phi_gb, ihi_phi_gb
      integer ilo_fb, ihi_fb
      double precision F_x(ilo_grad_F_gb:ihi_grad_F_gb)
      double precision F_x_plus(
     &                   ilo_grad_F_plus_gb:ihi_grad_F_plus_gb)
      double precision F_x_minus(
     &                   ilo_grad_F_minus_gb:ihi_grad_F_minus_gb)
      double precision phi(ilo_phi_gb:ihi_phi_gb)
      double precision phi_cur
      double precision phi_neighbor_plus, phi_neighbor_minus
      integer i
      double precision zero
      parameter (zero=0.0d0)

c     compute "phi-upwind" derivatives
c     { begin loop over grid
      do i=ilo_fb,ihi_fb

c       cache current phi
        phi_cur = phi(i)

c       { begin computation of "upwind" derivative
        if (phi_cur .gt. 0) then

c         compute "upwind" derivative in x-direction

          phi_neighbor_minus = phi(i-1)
          phi_neighbor_plus = phi(i+1)
          if (phi_neighbor_minus .le. phi_cur) then
            if (phi_neighbor_plus .lt. phi_neighbor_minus) then
              F_x(i) = F_x_plus(i) 
            else
              F_x(i) = F_x_minus(i) 
            endif
          elseif (phi_neighbor_plus .le. phi_cur) then
            F_x(i) = F_x_plus(i) 
          else
            F_x(i) = zero
          endif

        elseif (phi_cur .lt. 0) then

c        compute "upwind" derivative in x-direction

          phi_neighbor_minus = phi(i-1)
          phi_neighbor_plus = phi(i+1)
          if (phi_neighbor_minus .ge. phi_cur) then
          if (phi_neighbor_plus .gt. phi_neighbor_minus) then
              F_x(i) = F_x_plus(i) 
            else
              F_x(i) = F_x_minus(i) 
            endif
          elseif (phi_neighbor_plus .ge. phi_cur) then
            F_x(i) = F_x_plus(i) 
          else
            F_x(i) = zero
          endif

c       } end computation of "upwind" derivative
        endif

      enddo
c     } end loop over grid

      return
      end
c } end subroutine
c***********************************************************************

c***********************************************************************
c
c  lsm1dAverageGradPhi() computes the average of the plus and minus 
c  derivatives:
c
c    phi_* = (phi_*_plus + phi_*_minus) / 2
c
c  Arguments:
c    phi_* (out):       components of average grad(phi)
c    phi_*_plus (in):   components of grad(phi) in plus direction
c    phi_*_minus (in):  components of grad(phi) in minus direction
c    *_gb (in):         index range for ghostbox
c    *_fb (in):         index range for fillbox
c
c***********************************************************************
      subroutine lsm1dAverageGradPhi(
     &  phi_x,
     &  ilo_grad_phi_gb, ihi_grad_phi_gb,
     &  phi_x_plus,
     &  ilo_grad_phi_plus_gb, ihi_grad_phi_plus_gb,
     &  phi_x_minus,
     &  ilo_grad_phi_minus_gb, ihi_grad_phi_minus_gb,
     &  ilo_fb, ihi_fb)
c***********************************************************************
c { begin subroutine
      implicit none

c     _gb refers to ghostbox 
c     _fb refers to fill-box

      integer ilo_grad_phi_gb, ihi_grad_phi_gb
      integer ilo_grad_phi_plus_gb, ihi_grad_phi_plus_gb
      integer ilo_grad_phi_minus_gb, ihi_grad_phi_minus_gb
      integer ilo_fb, ihi_fb
      double precision phi_x(ilo_grad_phi_gb:ihi_grad_phi_gb)
      double precision phi_x_plus(
     &                   ilo_grad_phi_plus_gb:ihi_grad_phi_plus_gb)
      double precision phi_x_minus(
     &                   ilo_grad_phi_minus_gb:ihi_grad_phi_minus_gb)
      integer i
      double precision half
      parameter (half=0.5d0)

c     compute "phi-upwind" derivatives
c     { begin loop over grid
      do i=ilo_fb,ihi_fb

        phi_x(i) = half * ( phi_x_plus(i) 
     &                      + phi_x_minus(i) )

      enddo
c     } end loop over grid

      return
      end
c } end subroutine
c***********************************************************************
