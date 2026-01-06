import numpy as np
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation
import pandas as pd
import os

def animate_orbit():
    # Setup paths
    script_dir = os.path.dirname(os.path.abspath(__file__))
    # Assuming the Fortran executable runs in the project root, the csv will be there.
    # However, if run from elsewhere, we need to find it.
    # Let's assume it's in the project root (parent of viz)
    project_root = os.path.dirname(script_dir)
    data_file = os.path.join(project_root, 'orbit_data.csv')
    
    if not os.path.exists(data_file):
        # Fallback: check if it's in the current directory
        if os.path.exists('orbit_data.csv'):
            data_file = 'orbit_data.csv'
        else:
            print(f"Error: {data_file} not found. Please run the Fortran simulation first.")
            return

    print(f"Loading data from {data_file}...")
    
    # Read CSV
    # The Fortran output uses fixed-width formatting (spaces), but the header uses commas.
    # We must skip the header and provide names manually to ensure correct parsing.
    try:
        df = pd.read_csv(data_file, delim_whitespace=True, skiprows=1, names=['Time', 'X', 'Y', 'Z', 'Vx', 'Vy', 'Vz'])
    except Exception as e:
        print(f"Error reading CSV: {e}")
        return

    # Check if data is empty
    if df.empty:
        print("Error: DataFrame is empty. Check orbit_data.csv.")
        return

    # Extract data
    t = df['Time'].values
    x = df['X'].values
    y = df['Y'].values
    z = df['Z'].values
    
    # Earth Parameters for visualization
    R_earth = 6371.0e3 # meters

    # Create figure
    fig = plt.figure(figsize=(12, 12)) # Bigger figure
    ax = fig.add_subplot(111, projection='3d')
    
    # Create Earth Sphere (Optimized for performance)
    # Reduced grid density from 60 to 30 to reduce lag
    u = np.linspace(0, 2 * np.pi, 30)
    v = np.linspace(0, np.pi, 30)
    EARTH_X = R_earth * np.outer(np.cos(u), np.sin(v))
    EARTH_Y = R_earth * np.outer(np.sin(u), np.sin(v))
    EARTH_Z = R_earth * np.outer(np.ones(np.size(u)), np.cos(v))
    
    # Plot Earth (Surface + Wireframe)
    # Alpha blending is expensive, so we keep grid low
    ax.plot_surface(EARTH_X, EARTH_Y, EARTH_Z, color='cyan', alpha=0.15)
    ax.plot_wireframe(EARTH_X, EARTH_Y, EARTH_Z, color='blue', alpha=0.1, linewidth=0.5)
    
    # Initialize orbit line and satellite point
    line, = ax.plot([], [], [], 'r-', label='Orbit Path', linewidth=2)
    point, = ax.plot([], [], [], 'ko', label='Satellite', markersize=8, markeredgecolor='white')
    
    # Set axis limits based on max orbit radius (plus small buffer for zoom)
    if len(x) > 0:
        max_dist = max(np.max(np.abs(x)), np.max(np.abs(y)), np.max(np.abs(z)))
        max_range = max_dist * 1.1 # Zoomed in (1.1x instead of 1.5x)
    else:
        max_range = R_earth * 1.5
    
    ax.set_xlim(-max_range, max_range)
    ax.set_ylim(-max_range, max_range)
    ax.set_zlim(-max_range, max_range)
    
    ax.set_xlabel('X (m)')
    ax.set_ylabel('Y (m)')
    ax.set_zlabel('Z (m)')
    ax.set_title('Satellite Orbit Simulation')
    ax.legend()
    
    # Animation update function
    def update(frame):
        # frame is the index
        # To speed up animation, we can skip frames if needed, but let's do 1:1 first
        idx = frame 
        
        # Update path up to current index
        line.set_data(x[:idx], y[:idx])
        line.set_3d_properties(z[:idx])
        
        # Update satellite position
        point.set_data([x[idx]], [y[idx]]) # Must be sequence
        point.set_3d_properties([z[idx]])
        
        # Update title with time
        ax.set_title(f'Satellite Orbit Simulation (Time: {t[idx]:.1f} s)')
        
        return line, point

    # Create animation
    # frames = number of steps
    # interval = delay in ms
    # Optimized: skip frames more often and increase delay to reduce CPU load
    skip = 15 
    frames_indices = range(0, len(t), skip)
    
    # interval=50ms means max 20 FPS, which is smoother for heavy 3D plots
    anim = FuncAnimation(fig, update, frames=frames_indices, interval=50, blit=False)
    
    print("Close the window to end the animation script.")
    plt.show()

if __name__ == "__main__":
    animate_orbit()