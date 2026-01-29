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
# Ensure bin directory exists
mkdir -p bin

# Compile to a clean filename (not conflicting with the Git placeholder)
gfortran -O3 \
    src/mod_precision.f90 \
    src/mod_constants.f90 \
    src/mod_physics.f90 \
    src/main.f90 \
    -o bin/orbit_sim_linux \
    -static-libgfortran -static-libquadmath

# 4. Permissions
chmod +x bin/orbit_sim_linux

# List bin content to verify build
echo "Build Directory Contents (bin):"
ls -la bin/

echo "-----------------------------------"
echo "Build and Compilation Complete"
echo "-----------------------------------"

echo "-----------------------------------"
echo "Build and Compilation Complete"
echo "-----------------------------------"
