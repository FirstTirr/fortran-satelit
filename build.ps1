$srcDir = "src"
$buildDir = "build"
$exeDir = "exe"
$exeName = "orbit_sim.exe"

# Clean old executable
if (Test-Path "$exeDir/$exeName") { Remove-Item "$exeDir/$exeName" }

# Create directories if they don't exist
if (-not (Test-Path $buildDir)) { New-Item -ItemType Directory -Path $buildDir | Out-Null }
if (-not (Test-Path $exeDir)) { New-Item -ItemType Directory -Path $exeDir | Out-Null }

# Compile Modules first
Write-Host "Compiling modules..."
gfortran -c "$srcDir/mod_precision.f90" -J $buildDir -o "$buildDir/mod_precision.o"
gfortran -c "$srcDir/mod_constants.f90" -J $buildDir -o "$buildDir/mod_constants.o"
gfortran -c "$srcDir/mod_physics.f90" -J $buildDir -o "$buildDir/mod_physics.o"

# Compile Main
Write-Host "Compiling main program..."
gfortran "$srcDir/main.f90" "$buildDir/mod_precision.o" "$buildDir/mod_constants.o" "$buildDir/mod_physics.o" -I $buildDir -o "$exeDir/$exeName"

if ($?) {
    Write-Host "Build successful! Executable located at $exeDir/$exeName"
} else {
    Write-Host "Build failed."
}