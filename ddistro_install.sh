#!/bin/bash

# Function to handle errors
handle_error() {
    echo "ERROR: $1" >&2
    echo "Continuing with installation..."
    echo "Press ENTER to continue"
    read -r
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

# Install requirements
echo "This will take a while so please wait."
echo "Installing requirements..."
pip install -r requirements.txt || handle_error "Failed to install requirements"

# Download unidic
echo "This download will take a while....be patient"
echo "Downloading unidic models..."
python -m unidic download || handle_error "Failed to download unidic models"

# Install package
echo "Installing package..."
pip install -e . || handle_error "Failed to install package"

# Install NLTK
echo "Installing NLTK components..."
python3 install_nltk.py || handle_error "Failed to install NLTK components"

# Run configuration
echo "Running configuration script..."
./conf.sh || handle_error "Failed to run configuration script"

echo "Installation process completed!"
