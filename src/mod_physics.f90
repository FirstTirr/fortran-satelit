module mod_physics
    use mod_precision
    use mod_constants
    implicit none
    
    private
    public :: state_type, get_derivatives, rk4_step, norm2

    type :: state_type
        real(dp) :: r(3) ! Position (x, y, z)
        real(dp) :: v(3) ! Velocity (vx, vy, vz)
    end type state_type

contains

    ! Calculate Euclidean norm
    function norm2(vec) result(res)
        real(dp), intent(in) :: vec(3)
        real(dp) :: res
        res = sqrt(vec(1)**2 + vec(2)**2 + vec(3)**2)
    end function norm2

    ! Compute derivatives [dr/dt, dv/dt]
    ! dr/dt = v
    ! dv/dt = -GM/|r|^3 * r
    function get_derivatives(current_state) result(derivs)
        type(state_type), intent(in) :: current_state
        type(state_type) :: derivs
        
        real(dp) :: pos_mag, accel_mag
        
        derivs%r = current_state%v
        
        pos_mag = norm2(current_state%r)
        
        ! a = -GM / r^3 * r vector
        accel_mag = -(G * M_earth) / (pos_mag**3)
        derivs%v = accel_mag * current_state%r
        
    end function get_derivatives

    ! Runge-Kutta 4th Order Integrator
    subroutine rk4_step(state, dt)
        type(state_type), intent(inout) :: state
        real(dp), intent(in) :: dt
        
        type(state_type) :: k1, k2, k3, k4, temp_state
        
        ! K1
        k1 = get_derivatives(state)
        
        ! K2
        temp_state%r = state%r + 0.5_dp * dt * k1%r
        temp_state%v = state%v + 0.5_dp * dt * k1%v
        k2 = get_derivatives(temp_state)
        
        ! K3
        temp_state%r = state%r + 0.5_dp * dt * k2%r
        temp_state%v = state%v + 0.5_dp * dt * k2%v
        k3 = get_derivatives(temp_state)
        
        ! K4
        temp_state%r = state%r + dt * k3%r
        temp_state%v = state%v + dt * k3%v
        k4 = get_derivatives(temp_state)
        
        ! Update state
        state%r = state%r + (dt / 6.0_dp) * (k1%r + 2.0_dp*k2%r + 2.0_dp*k3%r + k4%r)
        state%v = state%v + (dt / 6.0_dp) * (k1%v + 2.0_dp*k2%v + 2.0_dp*k3%v + k4%v)
        
    end subroutine rk4_step

end module mod_physics