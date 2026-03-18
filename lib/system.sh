#!/bin/bash

# Ghostarch System Functions
# Environment checks, validation, and system configuration

check_root() {
    if [[ $EUID -eq 0 ]]; then
        if [[ -f /proc/version ]] && grep -qi microsoft /proc/version 2>/dev/null; then
            log_warn "Running as root in WSL2 - some features may not work"
            log_info "Consider running as regular user with sudo"
        else
            log_warn "Running as root - some features may not work as expected"
        fi
    fi
}

check_wsl() {
    if [[ ! -f /proc/version ]] || ! grep -qi microsoft /proc/version; then
        log_warn "This script is designed for WSL2. Running on regular Linux"
    else
        log_info "WSL2 environment detected"
    fi
}

check_network() {
    log_info "Checking network connectivity..."
    if curl -sf --max-time 10 https://blackarch.org >/dev/null 2>&1; then
        log_info "Network connectivity OK"
        return 0
    else
        log_error "No network connectivity"
        return 1
    fi
}

check_sudo() {
    if ! sudo -v 2>/dev/null; then
        log_error "sudo privileges required"
        exit 1
    fi
    log_info "sudo privileges available"
}

add_blackarch_repo() {
    log_info "Adding BlackArch repository..."

    local strap_sh="/tmp/strap.sh"

    curl -fsSL https://blackarch.org/strap.sh -o "$strap_sh"

    log_info "Verifying strap.sh checksum..."
    if curl -fsSL https://blackarch.org/strap.sh.sha256sum | sha256sum -c 2>/dev/null; then
        log_info "Checksum verified"
    else
        log_warn "Checksum verification failed, proceeding anyway"
    fi

    log_info "Running BlackArch strap script..."
    sudo bash "$strap_sh"
    rm -f "$strap_sh"

    log_info "Installing BlackArch keyring..."
    if pacman -Qs blackarch-keyring >/dev/null 2>&1; then
        log_info "BlackArch keyring already installed, skipping"
    else
        sudo pacman -S --noconfirm --overwrite='*' blackarch-keyring || log_warn "Keyring installation had issues, continuing..."
    fi
}
