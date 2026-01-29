from flask import Flask, jsonify, send_from_directory, request
import subprocess
import os
import pandas as pd
import shutil
import site

app = Flask(__name__, static_folder='ui')

# Enable CORS manually to allow requests from Live Server (port 5500)
@app.after_request
def after_request(response):
    response.headers.add('Access-Control-Allow-Origin', '*')
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
    response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS')
    # Prevent caching
    response.headers.add('Cache-Control', 'no-store, no-cache, must-revalidate, max-age=0')
    response.headers.add('Pragma', 'no-cache')
    response.headers.add('Expires', '0')
    return response

# Configuration
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

# Detect OS to determine executable name
if os.name == 'nt': # Windows
    EXE_NAME = 'orbit_sim.exe'
    EXE_PATH = os.path.join(BASE_DIR, 'exe', EXE_NAME)
    WORK_DIR = BASE_DIR
else: # Linux (Vercel/Docker)
    EXE_NAME = 'orbit_sim_linux' 
    EXE_PATH = None
    
    # Strategy 1: Look in site-packages (where build_vercel.sh installed it)
    try:
        site_packages = site.getsitepackages()
        for sp in site_packages:
            potential_path = os.path.join(sp, 'orbit_sim_data', 'orbit_sim_linux_bin')
            if os.path.exists(potential_path):
                # Found it! Copy to /tmp to ensure execution
                target_path = os.path.join('/tmp', EXE_NAME)
                shutil.copy(potential_path, target_path)
                os.chmod(target_path, 0o755)
                EXE_PATH = target_path
                break
    except Exception as e:
        print(f"Error searching site-packages: {e}")

    # Strategy 2: Fallbacks (bin folder, root, etc.)
    if not EXE_PATH:
        POSSIBLE_PATHS = [
            os.path.join(BASE_DIR, 'bin', EXE_NAME), 
            os.path.join(BASE_DIR, EXE_NAME),
            os.path.join('/var/task/bin', EXE_NAME)
        ]
        for path in POSSIBLE_PATHS:
            if os.path.exists(path):
                EXE_PATH = path
                break
    
    # Default to /tmp path for error reporting
    if not EXE_PATH:
        EXE_PATH = os.path.join('/tmp', EXE_NAME)

    WORK_DIR = '/tmp'
    
    # Validation
    if EXE_PATH and os.path.exists(EXE_PATH):
        try:
            # Check for ELF header to avoid running text files
            with open(EXE_PATH, 'rb') as f:
                header = f.read(4)
                if header != b'\x7fELF':
                    print(f"WARNING: {EXE_PATH} header is {header}, not ELF!")
        except:
            pass
            
    # Debug Route
    @app.route('/debug-system')
    def debug_system():
        debug_info = {
            'cwd': os.getcwd(),
            'base_dir': BASE_DIR,
            'exe_name': EXE_NAME,
            'resolved_exe_path': EXE_PATH,
            'exe_exists': os.path.exists(EXE_PATH) if EXE_PATH else False,
            'site_packages_scan': [
                (sp, os.path.exists(os.path.join(sp, 'orbit_sim_data', 'orbit_sim_linux_bin'))) 
                for sp in site.getsitepackages()
            ],
            'files_in_root': os.listdir(BASE_DIR),
            'files_in_bin': os.listdir(os.path.join(BASE_DIR, 'bin')) if os.path.exists(os.path.join(BASE_DIR, 'bin')) else 'bin missing',
            'env_user': os.environ.get('USER'),
            'env_home': os.environ.get('HOME')
        }
        
        # File Stats for EXE
        if EXE_PATH and os.path.exists(EXE_PATH):
            st = os.stat(EXE_PATH)
            debug_info['exe_stats'] = {
                'size': st.st_size,
                'mode': oct(st.st_mode),
                'mtime': st.st_mtime
            }
            # Read first few bytes
            try:
                with open(EXE_PATH, 'rb') as f:
                    debug_info['exe_header_hex'] = f.read(16).hex()
            except Exception as e:
                debug_info['exe_read_error'] = str(e)
                
        return jsonify(debug_info) 
    
    # PENTING: Di Vercel Serverless, file ini mungkin kehilangan permission execute-nya.
    # Kita paksa beri izin "chmod +x" sebelum dijalankan.
    if os.path.exists(EXE_PATH):
        import stat
        try:
            st = os.stat(EXE_PATH)
            os.chmod(EXE_PATH, st.st_mode | stat.S_IEXEC)
        except:
            pass

DATA_PATH = os.path.join(WORK_DIR, 'orbit_data.csv')

@app.route('/')
def index():
    # Serve the index.html file from the ui folder
    return send_from_directory('ui', 'index.html')

@app.route('/favicon.ico')
def favicon():
    return '', 204

@app.route('/run-simulation', methods=['POST'])
def run_simulation():
    try:
        # Get parameters from request or use defaults
        data = request.get_json() or {}
        altitude = str(data.get('altitude', '400'))
        velocity = str(data.get('velocity', '0'))
        duration = str(data.get('duration', '7000'))

        # 1. Run the Fortran Executable
        if not os.path.exists(EXE_PATH):
            # Debugging info
            debug_info = {
                'error': f"Executable not found at {EXE_PATH}. Please build the project first.",
                'cwd': os.getcwd(),
                'base_dir': BASE_DIR,
                'files_in_base': os.listdir(BASE_DIR),
                'files_in_bin': os.listdir(os.path.join(BASE_DIR, 'bin')) if os.path.exists(os.path.join(BASE_DIR, 'bin')) else 'bin folder missing'
            }
            return jsonify(debug_info), 500

        # Run process with user inputs
        # Inputs expected by main.f90:
        # 1. Altitude (km)
        # 2. Velocity (m/s) -> 0 for Auto
        # 3. Duration (s)
        input_str = f"{altitude}\n{velocity}\n{duration}\n"
        
        # Ensure WORK_DIR exists (especially /tmp logic)
        if not os.path.exists(WORK_DIR):
             os.makedirs(WORK_DIR, exist_ok=True)

        result = subprocess.run([EXE_PATH], cwd=WORK_DIR, input=input_str, capture_output=True, text=True)
        
        if result.returncode != 0:
            return jsonify({'error': 'Simulation failed', 'details': result.stderr}), 500

        # 2. Read the generated CSV output
        if not os.path.exists(DATA_PATH):
            return jsonify({'error': 'Output file orbit_data.csv not found.'}), 500

        # Read CSV (Skipping the unit/header line if necessary, adjusting based on your Main.f90 output)
        # Using delim_whitespace=True for Fortran's default spacing output
        df = pd.read_csv(DATA_PATH, delim_whitespace=True, skiprows=1, names=['Time', 'X', 'Y', 'Z', 'Vx', 'Vy', 'Vz'])

        # 3. Convert to JSON for the web
        data = {
            'time': df['Time'].tolist(),
            'x': df['X'].tolist(),
            'y': df['Y'].tolist(),
            'z': df['Z'].tolist()
        }
        
        return jsonify({'status': 'success', 'data': data, 'message': result.stdout})

    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    print(f"Starting server... Open http://localhost:5000 in your browser")
    # Host 0.0.0.0 is required for Docker/Vercel and allows LAN access
    app.run(host='0.0.0.0', debug=True, port=5000)
