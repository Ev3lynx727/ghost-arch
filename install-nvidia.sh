#!/bin/bash

# Ghostarch NVIDIA GPU Setup Script
# Run after install-ghostarch.sh for GPU acceleration in Arch WSL2
# Requires NVIDIA WSL2 drivers and CUDA-Core in Windows

set -euo pipefail

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}"

# Source common library
if [[ -f "${PROJECT_ROOT}/lib/common.sh" ]]; then
    source "${PROJECT_ROOT}/lib/common.sh"
else
    echo "Error: Could not find ${PROJECT_ROOT}/lib/common.sh"
    exit 1
fi

main() {
    init_logging

    log_info "Starting NVIDIA GPU Setup for WSL2"

    check_root
    check_wsl
    check_sudo
    load_config

    # Use GPU_PACKAGES from config if defined, else defaults
    local gpu_packages=("${GPU_PACKAGES[@]:-nvidia nvidia-utils cuda cuda-tools hashcat}")

    log_info "Installing NVIDIA GPU packages..."
    install_packages "${gpu_packages[@]}"

    log_info "Testing GPU setup..."
    if command -v nvidia-smi &>/dev/null; then
        nvidia-smi || log_warn "nvidia-smi failed, but drivers might still work"
    else
        log_warn "nvidia-smi not found"
    fi

    if command -v nvcc &>/dev/null; then
        nvcc --version
    else
        log_warn "nvcc not found"
    fi

    if command -v hashcat &>/dev/null; then
        log_info "Hashcat benchmark (short test):"
        hashcat --benchmark --benchmark-all | head -20 || log_warn "Hashcat benchmark failed"
    fi

    log_info "GPU setup complete. Use tools like 'hashcat -m 0 -a 3 hash.txt' for GPU acceleration."
    log_info "For more tools, install separately (e.g., john the ripper with CUDA)."
}

main "$@"
