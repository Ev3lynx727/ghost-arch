#!/bin/bash

# Ghostarch Installer - Main Entry Point
# WSL2 Arch Linux setup with BlackArch tools
#
# This script:
#   1. Installs core (zsh, oh-my-zsh, BlackArch repo)
#   2. Creates user and workspace
#   3. Sets default shell to zsh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${SCRIPT_DIR}/scripts"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

LOG_FILE="${LOG_FILE:-${HOME}/.ghostarch/install.log}"

log_info() { echo -e "${GREEN}[INFO]${NC} $*"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $*" >> "$LOG_FILE" 2>/dev/null || true; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $*" >> "$LOG_FILE" 2>/dev/null || true; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $*" >> "$LOG_FILE" 2>/dev/null || true; }

init_logging() {
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    chmod 644 "$LOG_FILE" 2>/dev/null || true
}

usage() {
    cat << EOF
Ghostarch Installer - Main Entry Point

USAGE:
    $0 [OPTIONS]

OPTIONS:
    -h, --help              Show this help message
    -n, --noninteractive   Run in non-interactive mode
    -d, --debug            Enable debug output

EXAMPLES:
    $0                      # Interactive installation
    $0 --noninteractive     # Non-interactive (use defaults)

MODULAR USAGE:
    ./scripts/install-core.sh    # Core only
    ./scripts/install-tools.sh   # Tools only
    ./scripts/install-nvidia.sh # GPU acceleration

EOF
    exit 0
}

NONINTERACTIVE=0
DEBUG=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage ;;
        -n|--noninteractive) NONINTERACTIVE=1 ;;
        -d|--debug) DEBUG=1 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

prompt_user_setup() {
    echo
    log_info "=== User Configuration ==="
    echo
    
    local user_choice="existing"
    local current_user
    
    if [[ "$NONINTERACTIVE" != "1" ]]; then
        echo -n "Create new user or use existing? (new/existing) [existing]: "
        read -r user_choice
        user_choice="${user_choice:-existing}"
    fi
    
    case "$user_choice" in
        new|NEW|New)
            local new_username="ghostuser"
            
            if [[ "$NONINTERACTIVE" != "1" ]]; then
                echo -n "Enter new username [ghostuser]: "
                read -r new_username
                new_username="${new_username:-ghostuser}"
            fi
            
            if id "$new_username" &>/dev/null; then
                log_warn "User $new_username already exists"
                TARGET_USER="$new_username"
            else
                log_info "Creating user: $new_username"
                useradd -m -G wheel "$new_username" 2>/dev/null || sudo useradd -m -G wheel "$new_username"
                
                if [[ "$NONINTERACTIVE" != "1" ]]; then
                    echo -n "Enter password for $new_username: "
                    read -rs password
                    echo
                    if [[ -n "$password" ]]; then
                        echo "$new_username:$password" | sudo chpasswd 2>/dev/null || log_warn "Failed to set password"
                    fi
                fi
                
                TARGET_USER="$new_username"
                log_info "User $new_username created successfully"
            fi
            ;;
        *)
            TARGET_USER=$(whoami)
            ;;
    esac
    
    echo
    log_info "Selected user: $TARGET_USER"
}

prompt_workdir_setup() {
    echo
    log_info "=== Working Directory Setup ==="
    echo
    
    local workdir="${HOME}/ghostarch"
    
    if [[ "$NONINTERACTIVE" != "1" ]]; then
        echo -n "Enter working directory path [$workdir]: "
        read -r workdir_input
        workdir="${workdir_input:-$workdir}"
    fi
    
    WORKDIR="$workdir"
    
    log_info "Creating working directory: $WORKDIR"
    mkdir -p "$WORKDIR"
    
    local init_git="yes"
    if [[ "$NONINTERACTIVE" != "1" ]]; then
        echo -n "Initialize git repository in workdir? (yes/no) [yes]: "
        read -r init_git
        init_git="${init_git:-yes}"
    fi
    
    if [[ "$init_git" == "yes" ]]; then
        if [[ ! -d "$WORKDIR/.git" ]]; then
            git -C "$WORKDIR" init 2>/dev/null || log_warn "Failed to initialize git"
        else
            log_info "Git repo already exists"
        fi
    fi
    
    local create_subdirs="yes"
    if [[ "$NONINTERACTIVE" != "1" ]]; then
        echo -n "Create subdirectories (tools, exploits, wordlists)? (yes/no) [yes]: "
        read -r create_subdirs
        create_subdirs="${create_subdirs:-yes}"
    fi
    
    if [[ "$create_subdirs" == "yes" ]]; then
        mkdir -p "$WORKDIR"/{tools,exploits,wordlists,reports,logs}
        log_info "Subdirectories created"
    fi
    
    echo
    log_info "Working directory: $WORKDIR"
    echo "  - tools/    (pentesting tools)"
    echo "  - exploits/ (exploit scripts)"
    echo "  - wordlists/ (password lists)"
    echo "  - reports/  (scan results)"
    echo "  - logs/    (tool logs)"
}

setup_zsh() {
    echo
    log_info "=== Setting Up Zsh ==="
    
    if command -v zsh &>/dev/null; then
        log_info "Setting zsh as default shell..."
        
        if [[ "$TARGET_USER" == "$(whoami)" ]]; then
            chsh -s /bin/zsh 2>/dev/null || log_warn "Failed to set zsh as default shell"
        else
            sudo chsh -s /bin/zsh "$TARGET_USER" 2>/dev/null || log_warn "Failed to set zsh for user $TARGET_USER"
        fi
        
        log_info "Zsh set as default shell"
    else
        log_warn "Zsh not installed, skipping shell change"
    fi
}

setup_zshrc() {
    echo
    log_info "=== Configuring Zsh RC ==="
    
    local zshrc_template="${SCRIPT_DIR}/templates/zshrc"
    local user_home
    local user_zshrc
    
    if [[ "$TARGET_USER" == "$(whoami)" ]]; then
        user_home="$HOME"
    else
        user_home=$(getent passwd "$TARGET_USER" | cut -d: -f6)
    fi
    
    user_zshrc="${user_home}/.zshrc"
    
    if [[ -f "$zshrc_template" ]]; then
        if [[ -f "$user_zshrc" ]]; then
            log_info "Backing up existing .zshrc to .zshrc.backup"
            cp "$user_zshrc" "${user_zshrc}.backup" 2>/dev/null || sudo cp "$user_zshrc" "${user_zshrc}.backup"
        fi
        
        log_info "Merging zshrc template to $user_zshrc"
        
        # Create header
        cat > "$user_zshrc" << 'HEADER'
# ============================================
# Ghostarch Zsh Configuration
# Generated by install-ghostarch.sh
# ============================================

HEADER
        
        # Append template content
        cat "$zshrc_template" >> "$user_zshrc"
        
        # Set ownership
        if [[ "$TARGET_USER" != "$(whoami)" ]]; then
            sudo chown "$TARGET_USER:$TARGET_USER" "$user_zshrc" 2>/dev/null || true
        fi
        
        log_info "Zshrc configured successfully"
    else
        log_warn "Zshrc template not found at $zshrc_template"
    fi
}

configure_wsl_default_user() {
    echo
    log_info "=== Configuring WSL Default User ==="
    
    if [[ -f /proc/version ]] && grep -qi microsoft /proc/version; then
        local wsl_conf="/etc/wsl.conf"
        
        log_info "Configuring WSL to default to user: $TARGET_USER"
        
        cat > "$wsl_conf" << EOF
[user]
default=$TARGET_USER
EOF
        
        log_info "WSL default user configured"
        echo
        echo "IMPORTANT: Please run these commands in Windows PowerShell to apply:"
        echo "  wsl --terminate ArchLinux"
        echo "  wsl -d ArchLinux"
        echo "This will restart WSL and apply the new default user."
    else
        log_info "Not running in WSL, skipping WSL configuration"
    fi
}

main() {
    init_logging
    
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
    
    echo "Step 1: Core Installation (zsh, oh-my-zsh, BlackArch)"
    echo "--------------------------------------------------------"
    "$SCRIPTS_DIR/install-core.sh" "$@"
    
    echo
    echo "Step 2: User & Workspace Setup"
    echo "--------------------------------------------------------"
    prompt_user_setup
    prompt_workdir_setup
    setup_zsh
    setup_zshrc
    configure_wsl_default_user
    
    echo
    echo "============================================"
    echo "  Installation Complete!"
    echo "============================================"
    echo
    echo "Summary:"
    echo "  User: $TARGET_USER"
    echo "  Working Directory: $WORKDIR"
    echo "  Default Shell: zsh"
    echo
    echo "IMPORTANT: Restart WSL to apply user changes:"
    echo "  wsl --terminate ArchLinux"
    echo "  wsl -d ArchLinux"
    echo
    echo "Next steps:"
    echo "  - Run ./scripts/install-tools.sh to install tools"
    echo "  - Run ./scripts/install-nvidia.sh for GPU acceleration (optional)"
    echo
    
    log_info "Installation completed successfully!"
}

main "$@"
