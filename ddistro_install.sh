#!/bin/bash

set -euo pipefail
export PIP_NO_CACHE_DIR=1
export PIP_DISABLE_PIP_VERSION_CHECK=1

# Function to handle errors
handle_error() {
    echo "ERROR: $1" >&2
    echo "Installation cannot continue."
    echo "Press ENTER to continue"
    read -r || true
    exit 1
}

# Navigate to directory
cd /home/dwemer/MeloTTS || {
    echo "ERROR: Could not access /home/dwemer/MeloTTS directory"
    echo "Please check if the directory exists and try again."
    echo "Press ENTER to exit"
    read -r
    exit 1
}

# Create Python virtual environment
echo "Creating Python virtual environment..."
python3 -m venv /home/dwemer/python-melotts || handle_error "Failed to create virtual environment"

# Activate virtual environment
echo "Activating virtual environment..."
source /home/dwemer/python-melotts/bin/activate || handle_error "Failed to activate virtual environment"

# Use DwemerDistro's validated CUDA selection; otherwise keep this environment CPU-only.
pytorch_gpu_available() {
    local cuda_home

    [ -r /var/lib/dwemerdistro/cuda-selection.env ] || return 1
    grep -qx 'CUDA_PYTORCH_SUPPORTED=1' /var/lib/dwemerdistro/cuda-selection.env || return 1
    cuda_home="$(sed -n 's|^CUDA_HOME=\(/usr/local/cuda-\(12\.8\|13\.0\)\)$|\1|p' /var/lib/dwemerdistro/cuda-selection.env | head -n 1)"
    [ -n "$cuda_home" ] && [ -x "$cuda_home/bin/nvcc" ]
}

# Install requirements
echo "This will take a while so please wait."
echo "Installing requirements..."
python -m pip install --no-cache-dir --upgrade pip 'setuptools<81' wheel || handle_error "Failed to install compatible packaging tools"
if pytorch_gpu_available; then
    python -m pip install --no-cache-dir --upgrade torch torchaudio --index-url https://download.pytorch.org/whl/cu128 || handle_error "Failed to install GPU PyTorch"
else
    python -m pip install --no-cache-dir --upgrade torch torchaudio --index-url https://download.pytorch.org/whl/cpu || handle_error "Failed to install CPU PyTorch"
fi
python -m pip install --no-cache-dir -r requirements.txt || handle_error "Failed to install requirements"

# Download unidic
echo "This download will take a while....be patient"
echo "Downloading unidic models..."
python -m unidic download || handle_error "Failed to download unidic models"

# Install package
echo "Installing package..."
python -m pip install --no-cache-dir -e . || handle_error "Failed to install package"

# Install NLTK
echo "Installing NLTK components..."
python3 install_nltk.py || handle_error "Failed to install NLTK components"

# Run configuration
echo "Running configuration script..."
bash ./conf.sh || handle_error "Failed to run configuration script"

echo "Installation process completed!"
