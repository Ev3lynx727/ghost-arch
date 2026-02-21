#!/bin/bash

# Ghostarch Installer - Main Entry Point
# Custom Arch WSL2 setup with selected BlackArch tools
# Inspired by BlackArch strap.sh, optimized for WSL2 and bleeding-edge tools
#
# This script orchestrates the full installation:
#   1. install-core.sh - First-time setup (zsh, oh-my-zsh, repos)
#   2. install-tools.sh - Post-installation (tools, user, workdir)
#
# For more control, run scripts individually:
#   ./install-core.sh    # Core setup only
#   ./install-tools.sh   # Tools and user configuration

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    cat << EOF
Ghostarch Installer - Main Entry Point

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -n, --noninteractive   Run in non-interactive mode
    -d, --debug             Enable debug output
    --core-only             Run only install-core.sh
    --tools-only            Run only install-tools.sh

EXAMPLES:
    $0                      # Full installation (core + tools)
    $0 --core-only          # Core setup only (zsh, repos)
    $0 --noninteractive     # Non-interactive full installation

MODULAR USAGE:
    ./install-core.sh       # First-time: zsh, oh-my-zsh, BlackArch repo
    ./install-tools.sh      # Post-install: tools, user config, workdir
    ./install-nvidia.sh     # Optional: GPU acceleration

EOF
    exit 0
}

CORE_ONLY=false
TOOLS_ONLY=false
NONINTERACTIVE=0
DEBUG=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage ;;
        -n|--noninteractive) NONINTERACTIVE=1 ;;
        -d|--debug) DEBUG=1 ;;
        --core-only) CORE_ONLY=true ;;
        --tools-only) TOOLS_ONLY=true ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

main() {
    echo "============================================"
    echo "  Ghostarch Installer v1.0.0"
    echo "  Custom Arch WSL2 with BlackArch Tools"
    echo "============================================"
    echo
    
    if [[ "$NONINTERACTIVE" == "1" ]]; then
        export NONINTERACTIVE=1
    fi
    
    if [[ "$DEBUG" == "1" ]]; then
        export DEBUG=1
    fi
    
    if [[ "$CORE_ONLY" == "true" ]]; then
        echo "Running core installation only..."
        exec "$SCRIPT_DIR/install-core.sh" "$@"
    fi
    
    if [[ "$TOOLS_ONLY" == "true" ]]; then
        echo "Running tools installation only..."
        exec "$SCRIPT_DIR/install-tools.sh" "$@"
    fi
    
    echo "Running full installation..."
    echo
    
    echo "Step 1/2: Core Installation (zsh, oh-my-zsh, BlackArch)"
    echo "--------------------------------------------------------"
    "$SCRIPT_DIR/install-core.sh" "$@"
    
    echo
    echo "Step 2/2: Tools Installation (packages, user, workdir)"
    echo "--------------------------------------------------------"
    "$SCRIPT_DIR/install-tools.sh" "$@"
    
    echo
    echo "============================================"
    echo "  Installation Complete!"
    echo "============================================"
    echo
    echo "Next steps:"
    echo "  - Optional: ./install-nvidia.sh for GPU acceleration"
    echo "  - Check your working directory for tools"
    echo
}

main "$@"
