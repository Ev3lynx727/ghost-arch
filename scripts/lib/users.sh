#!/bin/bash

# User and shell management library
# Provides functions for user creation, shell setup, and workspace configuration

create_user() {
    local username="${1:-}"
    local shell="${2:-/bin/zsh}"
    
    if [[ -z "$username" ]]; then
        log_error "Username is required"
        return 1
    fi
    
    if id "$username" &>/dev/null; then
        log_info "User $username already exists"
        return 0
    fi
    
    log_info "Creating user: $username"
    sudo useradd -m -s "$shell" -G wheel "$username"
    
    log_info "User $username created"
    return 0
}

setup_user_password() {
    local username="${1:-}"
    
    if [[ -z "$username" ]]; then
        log_error "Username is required"
        return 1
    fi
    
    if [[ "${NONINTERACTIVE:-0}" != "1" ]]; then
        if confirm "Set password for $username?" "Y"; then
            sudo passwd "$username"
        fi
    fi
    
    return 0
}

setup_zsh_default() {
    local username="${1:-$(whoami)}"
    
    if [[ "$username" == "$(whoami)" ]]; then
        chsh -s /bin/zsh 2>/dev/null || log_warn "Failed to set zsh default"
    else
        sudo chsh -s /bin/zsh "$username" 2>/dev/null || log_warn "Failed to set zsh for $username"
    fi
}

prompt_user_setup() {
    echo
    log_info "=== User Configuration ==="
    echo
    
    if [[ "${SKIP_USER:-false}" == "true" ]]; then
        log_warn "Skipping user configuration"
        return 0
    fi
    
    local user_choice
    prompt_user "Create new user or use existing? (new/existing)" "existing" user_choice
    
    case "$user_choice" in
        new|NEW|New)
            local new_username
            prompt_user "Enter new username" "ghostuser" new_username
            
            if id "$new_username" &>/dev/null; then
                log_warn "User $new_username already exists"
                TARGET_USER="$new_username"
            else
                log_info "Creating user: $new_username"
                sudo useradd -m -s /bin/zsh -G wheel "$new_username"
                
                local set_password
                prompt_user "Set password for $new_username? (yes/no)" "yes" set_password
                if [[ "$set_password" == "yes" ]]; then
                    sudo passwd "$new_username"
                fi
                
                TARGET_USER="$new_username"
                log_info "User $new_username created successfully"
            fi
            ;;
        existing|EXISTING|Existing)
            local current_user
            current_user=$(whoami)
            prompt_user "Enter username" "$current_user" TARGET_USER
            
            if ! id "$TARGET_USER" &>/dev/null; then
                log_error "User $TARGET_USER does not exist"
                return 1
            fi
            ;;
        *)
            log_error "Invalid choice"
            return 1
            ;;
    esac
    
    echo
    log_info "Selected user: $TARGET_USER"
    return 0
}

prompt_workdir_setup() {
    echo
    log_info "=== Working Directory Setup ==="
    echo
    
    if [[ "${SKIP_WORKDIR:-false}" == "true" ]]; then
        log_warn "Skipping working directory setup"
        return 0
    fi
    
    prompt_user "Enter working directory path" "${WORKDIR:-$HOME/ghostarch}" WORKDIR
    
    log_info "Creating working directory: $WORKDIR"
    sudo -u "${TARGET_USER:-$(whoami)}" mkdir -p "$WORKDIR"
    
    local init_git
    prompt_user "Initialize git repository in workdir? (yes/no)" "yes" init_git
    
    if [[ "$init_git" == "yes" ]]; then
        if [[ ! -d "$WORKDIR/.git" ]]; then
            sudo -u "${TARGET_USER:-$(whoami)}" git -C "$WORKDIR" init 2>/dev/null || log_warn "Failed to initialize git"
        else
            log_info "Git repository already exists"
        fi
    fi
    
    local create_subdirs
    prompt_user "Create subdirectories (tools, exploits, wordlists)? (yes/no)" "yes" create_subdirs
    
    if [[ "$create_subdirs" == "yes" ]]; then
        local subdirs=("tools" "exploits" "wordlists" "payloads" "reports")
        for subdir in "${subdirs[@]}"; do
            sudo -u "${TARGET_USER:-$(whoami)}" mkdir -p "$WORKDIR/$subdir" 2>/dev/null || true
        done
        log_info "Subdirectories created"
    fi
    
    log_info "Working directory setup complete: $WORKDIR"
    return 0
}
