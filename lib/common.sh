#!/bin/bash

# Ghostarch Common Library
# Shared helper functions for all installation scripts

set -euo pipefail

if [[ -z "${SCRIPT_DIR:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
if [[ -z "${PROJECT_ROOT:-}" ]]; then
    PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
fi
LOG_FILE="${LOG_FILE:-${HOME}/.ghostarch/install.log}"

GHOSTARCH_VERSION="1.0.0"
CONFIG_FILE="${PROJECT_ROOT}/config.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    local level="$1"
    shift
    local msg="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        INFO)  echo -e "${GREEN}[INFO]${NC} $msg" ;;
        WARN)  echo -e "${YELLOW}[WARN]${NC} $msg" ;;
        ERROR) echo -e "${RED}[ERROR]${NC} $msg" ;;
        DEBUG) [[ "${DEBUG:-0}" == "1" ]] && echo -e "${BLUE}[DEBUG]${NC} $msg" ;;
    esac
    
    echo "[$timestamp] [$level] $msg" >> "$LOG_FILE" 2>/dev/null || true
}

log_info()   { log "INFO" "$@"; }
log_warn()   { log "WARN" "$@"; }
log_error()  { log "ERROR" "$@"; }
log_debug()  { log "DEBUG" "$@"; }

init_logging() {
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    chmod 644 "$LOG_FILE" 2>/dev/null || true
    log_info "Ghostarch v${GHOSTARCH_VERSION} installation started"
}

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
    if curl -sf --max-time 10 https://blackarch.org > /dev/null 2>&1; then
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

load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        log_info "Loading configuration from $CONFIG_FILE"
        source "$CONFIG_FILE"
    else
        log_warn "Config file not found, using defaults"
    fi
}

confirm() {
    local prompt="${1:-Continue?}"
    local default="${2:-Y}"
    
    if [[ "${NONINTERACTIVE:-0}" == "1" ]]; then
        return 0
    fi
    
    local yn
    case "$default" in
        Y|y) yn="Y/n" ;;
        N|n) yn="y/N" ;;
        *)   yn="y/n" ;;
    esac
    
    echo -n "$prompt [$yn]: "
    read -r yn
    
    case "$yn" in
        Y|y|yes|Yes|YES) return 0 ;;
        N|n|no|No|NO)    return 1 ;;
        *) [[ "$default" == "Y" ]] && return 0 || return 1 ;;
    esac
}

prompt_user() {
    local prompt="$1"
    local default="${2:-}"
    local var_name="$3"
    
    if [[ "${NONINTERACTIVE:-0}" == "1" ]]; then
        eval "$var_name='$default'"
        return 0
    fi
    
    echo -n "$prompt"
    [[ -n "$default" ]] && echo -n " [$default]"
    echo -n ": "
    read -r input
    
    local result="${input:-$default}"
    eval "$var_name='$result'"
}

install_packages() {
    local packages=("$@")
    local package_list="${packages[*]}"
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        log_warn "No packages to install"
        return 0
    fi
    
    log_info "Installing packages: $package_list"
    sudo pacman -S --noconfirm --needed "${packages[@]}"
}

update_system() {
    log_info "Updating system..."
    sudo pacman -Syu --noconfirm
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
    if pacman -Qs blackarch-keyring > /dev/null 2>&1; then
        log_info "BlackArch keyring already installed, skipping"
    else
        sudo pacman -S --noconfirm --overwrite='*' blackarch-keyring || log_warn "Keyring installation had issues, continuing..."
    fi
}

cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_error "Installation failed with exit code $exit_code"
    fi
    exit $exit_code
}

trap cleanup EXIT
