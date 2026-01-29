#!/bin/bash
set -e

echo "-----------------------------------"
echo "Starting Vercel Build Script"
echo "-----------------------------------"

# 1. Install GFortran
# Vercel Build images use Amazon Linux 2023 which uses 'dnf'
echo "Installing GFortran..."
dnf install -y gcc-gfortran

# 2. Install Python Dependencies
echo "Installing Python dependencies..."
pip install -r requirements.txt

# 3. Compile Fortran Code
echo "Compiling Fortran..."
# Ensure bin directory exists (though git should preserve it now)
mkdir -p bin

gfortran -O3 \
    src/mod_precision.f90 \
    src/mod_constants.f90 \
    src/mod_physics.f90 \
    src/main.f90 \
    -o bin/orbit_sim_linux \
    -static-libgfortran -static-libquadmath

# 4. Permissions
chmod +x bin/orbit_sim_linux

echo "Build Directory Contents (bin):"
ls -la bin/

echo "-----------------------------------"
echo "Build and Compilation Complete"
echo "-----------------------------------"

echo "-----------------------------------"
echo "Build and Compilation Complete"
echo "-----------------------------------"
