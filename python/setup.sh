#!/bin/bash

# Check if pip3 is installed
if ! command -v pip3 &> /dev/null; then
    echo "pip3 is not installed. Please install Python3 and pip3 first."
    exit 1
fi

# Install required packages
echo "Installing required Python packages..."
pip3 install -r requirements.txt

# Test PDF parsing
echo "Testing PDF parsing..."
python3 -c "import pdfplumber; print('pdfplumber installed successfully')"

echo "Setup complete!" 