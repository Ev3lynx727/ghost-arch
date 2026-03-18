#!/bin/bash

# Ghostarch Prompt Functions
# User interaction and setup prompts

confirm() {
    local prompt="${1:-Continue?}"
    local default="${2:-Y}"

    if [[ "${NONINTERACTIVE:-0}" == "1" ]]; then
        return 0
    fi

    local yn
    case "$default" in
    Y | y) yn="Y/n" ;;
    N | n) yn="y/N" ;;
    *) yn="y/n" ;;
    esac

    echo -n "$prompt [$yn]: "
    read -r yn

    case "$yn" in
    Y | y | yes | Yes | YES) return 0 ;;
    N | n | no | No | NO) return 1 ;;
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

create_new_user() {
    local new_username="$1"

    if id "$new_username" &>/dev/null; then
        log_warn "User $new_username already exists"
        TARGET_USER="$new_username"
        log_info "Selected user: $TARGET_USER"
        return 0
    fi

    log_info "Creating user: $new_username"
    sudo useradd -m -s /bin/zsh -G wheel "$new_username"

    if [[ "${NONINTERACTIVE:-0}" != "1" ]]; then
        local set_password
        prompt_user "Set password for $new_username? (yes/no)" "yes" set_password
        [[ "$set_password" == "yes" ]] && sudo passwd "$new_username"
    fi

    TARGET_USER="$new_username"
    log_info "User $new_username created successfully"
    echo
    log_info "Selected user: $TARGET_USER"
}

handle_existing_user() {
    local current_user
    current_user=$(whoami)
    prompt_user "Enter username" "$current_user" TARGET_USER

    if ! id "$TARGET_USER" &>/dev/null; then
        log_error "User $TARGET_USER does not exist"
        return 1
    fi

    echo
    log_info "Selected user: $TARGET_USER"
    return 0
}

prompt_user_setup() {
    echo
    log_info "=== User Configuration ==="
    echo

    [[ "${SKIP_USER:-false}" == "true" ]] && {
        log_warn "Skipping user configuration"
        TARGET_USER="${TARGET_USER:-$(whoami)}"
        return 0
    }

    local user_choice
    prompt_user "Create new user or use existing? (new/existing)" "existing" user_choice

    [[ "$user_choice" == "new" ]] || [[ "$user_choice" == "NEW" ]] || [[ "$user_choice" == "New" ]] && {
        create_new_user "$(prompt_user_get_username)"
        return $?
    }

    handle_existing_user
}

prompt_user_get_username() {
    local new_username
    prompt_user "Enter new username" "ghostuser" new_username
    echo "$new_username"
}

setup_git_repo() {
    local workdir="$1"
    local target_user="$2"

    if [[ ! -d "$workdir/.git" ]]; then
        sudo -u "$target_user" git -C "$workdir" init || log_warn "Failed to initialize git"
    else
        log_info "Git repo already exists"
    fi
}

create_workdir_subdirs() {
    local workdir="$1"
    local target_user="$2"

    sudo -u "$target_user" mkdir -p "$workdir"/{tools,exploits,wordlists,reports,logs}
    log_info "Subdirectories created"
}

prompt_workdir_setup() {
    echo
    log_info "=== Working Directory Setup ==="
    echo

    [[ "${SKIP_WORKDIR:-false}" == "true" ]] && {
        log_warn "Skipping working directory setup"
        WORKDIR="${WORKDIR:-$HOME/ghostarch}"
        return 0
    }

    prompt_user "Enter working directory path" "${HOME}/ghostarch" WORKDIR

    log_info "Creating working directory: $WORKDIR"
    sudo -u "$TARGET_USER" mkdir -p "$WORKDIR"

    local init_git
    prompt_user "Initialize git repository in workdir? (yes/no)" "yes" init_git

    [[ "$init_git" != "yes" ]] && {
        echo
        log_info "Working directory: $WORKDIR"
        return 0
    }

    setup_git_repo "$WORKDIR" "$TARGET_USER"

    local create_subdirs
    prompt_user "Create subdirectories (tools, exploits, wordlists)? (yes/no)" "yes" create_subdirs

    [[ "$create_subdirs" != "yes" ]] && {
        echo
        log_info "Working directory: $WORKDIR"
        return 0
    }

    create_workdir_subdirs "$WORKDIR" "$TARGET_USER"

    echo
    log_info "Working directory: $WORKDIR"
}
