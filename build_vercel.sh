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

# 5. Verification & Redundancy
echo "Verifying Binary..."
ls -l bin/orbit_sim_linux

# Check file type (if 'file' command is available)
if command -v file &> /dev/null; then
    file bin/orbit_sim_linux
fi

# Dry Run / Smoke Test to ensure it's a valid executable
# Inject inputs: 400 (Alt), 0 (Auto Vel), 10 (Short Duration)
echo "Running Smoke Test..."
echo -e "400\n0\n10" | ./bin/orbit_sim_linux
if [ $? -eq 0 ]; then
    echo "Smoke Test PASSED: Binary is valid and executable."
else
    echo "Smoke Test FAILED: Binary could not be executed on build machine."
    exit 1
fi

# Copy to root as fallback (sometimes Vercel pathing is tricky)
cp bin/orbit_sim_linux .

echo "-----------------------------------"
echo "Build and Compilation Complete"
echo "-----------------------------------"

echo "-----------------------------------"
echo "Build and Compilation Complete"
echo "-----------------------------------"
