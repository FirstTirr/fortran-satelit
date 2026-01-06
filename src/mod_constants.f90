module mod_constants
    use mod_precision
    implicit none
    
    ! Gravitational Constant (m^3 kg^-1 s^-2)
    real(dp), parameter :: G = 6.67430e-11_dp
    
    ! Earth Parameters
    real(dp), parameter :: M_earth = 5.972e24_dp  ! Mass of Earth (kg)
    real(dp), parameter :: R_earth = 6371.0e3_dp  ! Radius of Earth (m)
    
    ! Time constants
    real(dp), parameter :: day_seconds = 86400.0_dp
    
end module mod_constants