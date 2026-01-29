# Use Python base image
FROM python:3.9-slim

# Install GFortran compiler and Make tools
RUN apt-get update && \
    apt-get install -y gfortran build-essential && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY . .

# Compile the Fortran code inside the container (Linux environment)
# Order: Modules first, then Main
RUN gfortran -c src/mod_precision.f90 -o mod_precision.o && \
    gfortran -c src/mod_constants.f90 -o mod_constants.o && \
    gfortran -c src/mod_physics.f90 -o mod_physics.o && \
    gfortran src/main.f90 mod_precision.o mod_constants.o mod_physics.o -o orbit_sim

# Make sure the binary has execution permissions
RUN chmod +x orbit_sim

# Expose port (Render/Railway use env variable PORT normally, but we expose 5000 as default)
EXPOSE 5000

# Run the application using Gunicorn (Production Server)
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]
