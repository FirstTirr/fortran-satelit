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

# 6. PERSISTENCE HACK (Use Python's dist-packages/site-packages)
# This is the only folder guaranteed to be carried over from Build to Runtime by Vercel for Python apps
echo "Installing binary to Python Lib..."

# Get the location where pip installs packages
LIB_PATH=$(python3 -c "import site; print(site.getsitepackages()[0])")

# Ensure the directory exists
DATA_DIR="$LIB_PATH/fortran_bin"
mkdir -p "$DATA_DIR"

# Copy the binary
cp bin/orbit_sim_linux "$DATA_DIR/orbit_sim_linux"
chmod 755 "$DATA_DIR/orbit_sim_linux"

# Verify installation
echo "Binary installed to: $DATA_DIR/orbit_sim_linux"
ls -l "$DATA_DIR/orbit_sim_linux"

# Create a marker file so we can find it easily via Python import later if needed
site_pkg_marker="$DATA_DIR/__init__.py"
touch "$site_pkg_marker"

echo "-----------------------------------"
echo "Build and Compilation Complete"
echo "-----------------------------------"

echo "-----------------------------------"
echo "Build and Compilation Complete"
echo "-----------------------------------"
