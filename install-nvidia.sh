#!/bin/bash

# Ghostarch NVIDIA GPU Setup Script
# Run after install-ghostarch.sh for GPU acceleration in Arch WSL2
# Requires NVIDIA WSL2 drivers and CUDA-Core in Windows

set -e  # Exit on error

echo "Installing NVIDIA drivers for WSL2..."
sudo pacman -S nvidia nvidia-utils --noconfirm

echo "Installing CUDA toolkit..."
sudo pacman -S cuda cuda-tools --noconfirm

echo "Installing GPU-accelerated tools: hashcat..."
sudo pacman -S hashcat --noconfirm

echo "Testing GPU setup..."
nvidia-smi
echo "CUDA version:"
nvcc --version
echo "Hashcat benchmark (short test):"
hashcat --benchmark --benchmark-all | head -20  # Short test to verify GPU

echo "GPU setup complete. Use tools like 'hashcat -m 0 -a 3 hash.txt' for GPU acceleration."
echo "For more tools, install separately (e.g., john the ripper with CUDA)."