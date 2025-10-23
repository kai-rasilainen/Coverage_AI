#!/bin/bash
# setup_env.sh

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Setting up Python virtual environment and installing dependencies..."

# 1. DELETE the old environment
rm -rf venv

# 2. Create the virtual environment in the workspace
# Use '||' for fallback command (python3 or python)
python3 -m venv venv || python -m venv venv

# 3. Check if the venv was created successfully (e.g., check for the activate script)
if [ ! -f "venv/bin/activate" ]; then
    echo "ERROR: Failed to create virtual environment." >&2
    exit 1
fi

# 4. Install all required Python packages for AI and RAG
./venv/bin/python3 -m pip install --upgrade pip
./venv/bin/python3 -m pip install requests google-genai chromadb

echo "Python environment setup complete."
