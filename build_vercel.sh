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

# Check file type
if command -v file &> /dev/null; then
    file bin/orbit_sim_linux
fi

# Dry Run / Smoke Test
echo "Running Smoke Test..."
echo -e "400\n0\n10" | ./bin/orbit_sim_linux
if [ $? -eq 0 ]; then
    echo "Smoke Test PASSED."
else
    echo "Smoke Test FAILED."
    exit 1
fi

# 6. PERSISTENCE HACK (Save to site-packages)
# Vercel discards untracked build artifacts, but bundles site-packages.
# We determine the site-packages path and copy the binary there.
echo "Installing binary to site-packages for persistence..."
SITE_PACKAGES=$(python3 -c "import site; print(site.getsitepackages()[0])") 
echo "Site Packages: $SITE_PACKAGES"

# Copy binary to site-packages
mkdir -p "$SITE_PACKAGES/orbit_sim_data"
cp bin/orbit_sim_linux "$SITE_PACKAGES/orbit_sim_data/orbit_sim_linux_bin"
touch "$SITE_PACKAGES/orbit_sim_data/__init__.py"

echo "Listing site-package data:"
ls -la "$SITE_PACKAGES/orbit_sim_data/"

echo "-----------------------------------"
echo "Build and Compilation Complete"
echo "-----------------------------------"

echo "-----------------------------------"
echo "Build and Compilation Complete"
echo "-----------------------------------"
