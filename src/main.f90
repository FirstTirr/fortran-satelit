program satellite_orbit
    use mod_precision
    use mod_constants
    use mod_physics
    implicit none

    type(state_type) :: satellite
    real(dp) :: t, dt, t_max
    real(dp) :: altitude, velocity_mag
    real(dp) :: input_vel, v_circ
    integer :: steps, i
    character(len=100) :: output_file

    ! Simulation parameters
    t = 0.0_dp
    dt = 10.0_dp
    
    print *, "========================================="
    print *, "     SIMULASI ORBIT SATELIT (FORTRAN)    "
    print *, "========================================="
    print *
    
    ! --- INPUT 1: ALTITUDE ---
    print *, "1. Masukkan ketinggian satelit dari permukaan bumi (km):"
    print *, "   [Contoh: 400 untuk ISS, 35786 untuk Geostationary]"
    print *, "   Ketik angka (misal 400) lalu TEKAN ENTER:"
    read(*,*) altitude
    
    ! Validate input (basic)
    if (altitude < 100.0_dp) then
        print *, "   Peringatan: Ketinggian sangat rendah (< 100 km). Satelit akan jatuh."
    end if

    ! Convert km to meters
    altitude = altitude * 1000.0_dp 
    
    ! Calculate Circular Velocity reference
    v_circ = sqrt((G * M_earth) / (R_earth + altitude))
    
    print *
    print *, "   -> Kecepatan orbit melingkar sempurna pada ketinggian ini: ", v_circ, " m/s"
    print *
    
    ! --- INPUT 2: VELOCITY ---
    print *, "2. Masukkan kecepatan awal satelit (m/s):"
    print *, "   [PENTING: JANGAN KETIK SIMBOL < ATAU >. HANYA ANGKA]"
    print *, "   Opsi:"
    print *, "   - Ketik 0 : Otomatis (", int(v_circ), " m/s)"
    print *, "   - Ketik angka KECIL (misal ", int(v_circ - 500), ") : Orbit lonjong ke dalam"
    print *, "   - Ketik angka BESAR (misal ", int(v_circ + 500), ") : Orbit lonjong ke luar"
    print *, "   Ketik angka kecepatan lalu TEKAN ENTER:"
    read(*,*) input_vel
    
    if (input_vel > 0.1_dp) then
        velocity_mag = input_vel
        print *, "   -> KAMU MEMILIH KECEPATAN: ", velocity_mag, " m/s"
        
        if (velocity_mag < v_circ) then
            print *, "   (Status: Kecepatan di bawah kecepatan orbit circular)"
        else
            print *, "   (Status: Kecepatan di atas kecepatan orbit circular)"
        end if
    else
        velocity_mag = v_circ
        print *, "   -> MENGGUNAKAN OTOMATIS: ", velocity_mag, " m/s"
    end if
    print *

    ! --- INPUT 3: DURATION ---
    print *, "3. Berapa lama simulasi berjalan? (detik)"
    print *, "   [Saran: 6000 detik untuk 1x putaran LEO]"
    read(*,*) t_max
    
    ! Initial Conditions
    satellite%r = [R_earth + altitude, 0.0_dp, 0.0_dp]
    satellite%v = [0.0_dp, velocity_mag, 0.0_dp]
    
    ! Open output file
    output_file = "orbit_data.csv"
    open(unit=10, file=output_file, status='replace', action='write')
    write(10, *) "Time,X,Y,Z,Vx,Vy,Vz"

    print *
    print *, "Memulai simulasi..."
    print *, "Data akan disimpan ke: ", output_file

    steps = int(t_max / dt)
    
    do i = 1, steps
        write(10, '(F12.2, 6(1x, ES14.7))') t, satellite%r(1), satellite%r(2), satellite%r(3), &
                                           satellite%v(1), satellite%v(2), satellite%v(3)
        
        call rk4_step(satellite, dt)
        t = t + dt
        
        ! Progress bar simple
        if (mod(i, max(steps/10, 1)) == 0) then
            print *, "Progress: ", int((real(i)/real(steps))*100), "%"
        end if
    end do
    
    close(10)
    print *, "Simulasi Selesai!"
    print *, "Sekarang jalankan python via terminal: python satellite_orbit/viz/animate_orbit.py"
    
end program satellite_orbit