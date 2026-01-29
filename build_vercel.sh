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
# We strictly specify the output and correct source order
# We use -static flags so we don't depend on system .so libraries at runtime
echo "Compiling Fortran..."
mkdir -p exe
gfortran -O3 \
    src/mod_precision.f90 \
    src/mod_constants.f90 \
    src/mod_physics.f90 \
    src/main.f90 \
    -o exe/orbit_sim_linux \
    -static-libgfortran -static-libquadmath

# 4. Permissions
chmod +x exe/orbit_sim_linux

echo "-----------------------------------"
echo "Build and Compilation Complete"
echo "-----------------------------------"
