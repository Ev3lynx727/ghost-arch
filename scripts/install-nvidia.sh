#!/bin/bash

# Ghostarch NVIDIA GPU Setup Script
# Integrates with common.sh framework
# Run after install-ghostarch.sh for GPU acceleration in Arch WSL2
# Requires NVIDIA WSL2 drivers and CUDA-Core in Windows

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Install NVIDIA GPU drivers and CUDA toolkit for WSL2 Arch.

OPTIONS:
    -h, --help          Show this help
    -n, --noninteractive  Skip prompts, use defaults
    -d, --debug         Enable debug logging
    --skip-test         Skip GPU verification tests

EXAMPLES:
    $0                     # Interactive install with tests
    $0 --noninteractive   # Automated install (CI)
    $0 --skip-test        # Install without benchmarking

EOF
    exit 0
}

SKIP_TEST=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage ;;
        -n|--noninteractive) NONINTERACTIVE=1 ;;
        -d|--debug) DEBUG=1 ;;
        --skip-test) SKIP_TEST=true ;;
        *) log_error "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

main() {
    init_logging

    log_info "=== NVIDIA GPU Setup ==="

    check_root
    check_wsl
    load_config

    log_info "Installing NVIDIA packages..."
    local packages
    if declare -p GPU_PACKAGES &>/dev/null; then
        packages=("${GPU_PACKAGES[@]}")
    else
        packages=(nvidia nvidia-utils cuda cuda-tools hashcat)
    fi
    install_packages "${packages[@]}"

    if [[ "$SKIP_TEST" != "true" ]]; then
        log_info "Verifying GPU installation..."
        if command -v nvidia-smi &>/dev/null; then
            log_info "nvidia-smi output:"
            nvidia-smi
            log_info "CUDA version:"
            nvcc --version 2>/dev/null || log_warn "nvcc not found"
            log_info "Hashcat benchmark (short):"
            hashcat --benchmark --benchmark-all 2>/dev/null | head -20 || log_warn "Hashcat benchmark failed"
        else
            log_warn "nvidia-smi not available; GPU may not be accessible in WSL2"
        fi
    fi

    log_info "GPU setup complete. Tools ready."
    echo
    echo "Next: Try 'hashcat -m 0 -a 3 hash.txt' to test GPU acceleration."
}

main "$@"
