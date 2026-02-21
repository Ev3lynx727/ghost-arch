#!/bin/bash

# Ghostarch Core Installation Script
# First-time setup: zsh, oh-my-zsh, BlackArch repository
# Run this once after fresh Arch Linux WSL2 installation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Ghostarch Core Installation - First-time setup

OPTIONS:
    -h, --help              Show this help message
    -n, --noninteractive   Run in non-interactive mode
    -d, --debug            Enable debug output
    --skip-zsh             Skip zsh installation
    --skip-omz             Skip oh-my-zsh installation
    --skip-blackarch       Skip BlackArch repository

EXAMPLES:
    $0                      # Interactive installation
    $0 --noninteractive     # Non-interactive installation
    $0 --skip-blackarch    # Skip BlackArch (already added)

EOF
    exit 0
}

SKIP_ZSH=false
SKIP_OMZ=false
SKIP_BLACKARCH=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage ;;
        -n|--noninteractive) NONINTERACTIVE=1 ;;
        -d|--debug) DEBUG=1 ;;
        --skip-zsh) SKIP_ZSH=true ;;
        --skip-omz) SKIP_OMZ=true ;;
        --skip-blackarch) SKIP_BLACKARCH=true ;;
        *) log_error "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

main() {
    log_info "Starting Ghostarch Core Installation"
    
    check_root
    check_wsl
    
    if [[ "$SKIP_ZSH" != "true" ]] && [[ "$SKIP_OMZ" != "true" ]]; then
        check_network || exit 1
    fi
    
    check_sudo
    init_logging
    load_config
    
    log_info "=== System Update ==="
    update_system
    
    if [[ "$SKIP_ZSH" != "true" ]]; then
        log_info "=== Installing Zsh ==="
        install_packages zsh
        
        log_info "Setting zsh as default shell..."
        chsh -s /bin/zsh || log_warn "Failed to set zsh as default shell"
    fi
    
    if [[ "$SKIP_OMZ" != "true" ]]; then
        log_info "=== Installing Oh-My-Zsh ==="
        
        if [[ -d "$HOME/.oh-my-zsh" ]]; then
            log_warn "Oh-My-Zsh already installed, skipping..."
        else
            log_info "Cloning Oh-My-Zsh..."
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || log_warn "Oh-My-Zsh installation failed"
        fi
        
        log_info "Installing Oh-My-Zsh plugins..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" 2>/dev/null || true
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" 2>/dev/null || true
    fi
    
    log_info "=== Cloning Ghostarch Repository ==="
    local ghostarch_dir="${SCRIPT_DIR}"
    if [[ ! -d "$ghostarch_dir/.git" ]]; then
        git clone https://github.com/sst/ghost-arch.git /tmp/ghost-arch-temp 2>/dev/null || log_warn "Failed to clone ghost-arch repo"
        if [[ -d /tmp/ghost-arch-temp ]]; then
            cp -r /tmp/ghost-arch-temp/* "$ghostarch_dir/" 2>/dev/null || true
            rm -rf /tmp/ghost-arch-temp
        fi
    else
        log_info "Ghostarch repo already exists"
    fi
    
    if [[ "$SKIP_BLACKARCH" != "true" ]]; then
        log_info "=== Adding BlackArch Repository ==="
        add_blackarch_repo
    else
        log_warn "Skipping BlackArch repository setup"
    fi
    
    log_info "=== Core Installation Complete ==="
    echo
    echo "Next steps:"
    echo "  1. Run ./install-tools.sh to install tools and configure user"
    echo "  2. Optionally run ./install-nvidia.sh for GPU acceleration"
    echo
}

main "$@"
