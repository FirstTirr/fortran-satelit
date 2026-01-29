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
# We output to the root directory to overwrite the placeholder file
echo "Compiling Fortran..."
gfortran -O3 \
    src/mod_precision.f90 \
    src/mod_constants.f90 \
    src/mod_physics.f90 \
    src/main.f90 \
    -o orbit_sim_linux \
    -static-libgfortran -static-libquadmath

# 4. Permissions
chmod +x orbit_sim_linux

echo "Build Directory Contents:"
ls -la

echo "-----------------------------------"
echo "Build and Compilation Complete"
echo "-----------------------------------"

echo "-----------------------------------"
echo "Build and Compilation Complete"
echo "-----------------------------------"
