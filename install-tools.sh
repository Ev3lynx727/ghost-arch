#!/bin/bash

# Ghostarch Tools Installation Script
# Post-installation: tools, user configuration, working directory
# Run this after install-core.sh

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

# Source user management library
if [[ -f "${PROJECT_ROOT}/lib/users.sh" ]]; then
    source "${PROJECT_ROOT}/lib/users.sh"
fi

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Ghostarch Tools Installation - Post-installation setup

OPTIONS:
    -h, --help              Show this help message
    -n, --noninteractive   Run in non-interactive mode
    -d, --debug            Enable debug output
    -l, --list-groups      Show available package groups
    --skip-networking      Skip networking tools
    --skip-programming     Skip programming languages
    --skip-pentest         Skip pentest tools
    --skip-recon           Skip recon tools
    --skip-additional      Skip additional tools
    --skip-user            Skip user configuration
    --skip-workdir         Skip working directory setup

EXAMPLES:
    $0                      # Interactive installation with user prompts
    $0 --noninteractive     # Non-interactive with defaults
    $0 --skip-user          # Skip user creation prompts
    $0 --list-groups        # Show all package groups and their packages

EOF
    exit 0
}

SKIP_NETWORKING=false
SKIP_PROGRAMMING=false
SKIP_PENTEST=false
SKIP_RECON=false
SKIP_ADDITIONAL=false
export SKIP_USER=false
export SKIP_WORKDIR=false
LIST_GROUPS=false

# Package group mapping for DRY processing (config mode fallback)
declare -A GROUPS=(
    [networking]="NETWORKING_PACKAGES 'Networking Tools'"
    [programming]="PROGRAMMING_PACKAGES 'Programming Languages'"
    [pentest]="PENTEST_PACKAGES 'Pentest Tools'"
    [recon]="RECON_PACKAGES 'Recon Tools'"
    [additional]="ADDITIONAL_PACKAGES 'Additional Tools'"
)

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage ;;
        -n|--noninteractive) export NONINTERACTIVE=1 ;;
        -d|--debug) export DEBUG=1 ;;
        -l|--list-groups) LIST_GROUPS=true ;;
        --skip-networking) SKIP_NETWORKING=true ;;
        --skip-programming) SKIP_PROGRAMMING=true ;;
        --skip-pentest) SKIP_PENTEST=true ;;
        --skip-recon) SKIP_RECON=true ;;
        --skip-additional) SKIP_ADDITIONAL=true ;;
        --skip-user) export SKIP_USER=true ;;
        --skip-workdir) export SKIP_WORKDIR=true ;;
        *) log_error "Unknown option: $1"; exit 1 ;;
    esac
    shift
done

install_tool_group() {
    local group_name="$1"
    shift
    local packages=("$@")
    
    if [[ ${#packages[@]} -eq 0 ]]; then
        return 0
    fi
    
    log_info "=== Installing $group_name ==="
    
    local install_now=true
    if [[ "${NONINTERACTIVE:-0}" != "1" ]]; then
        echo "Packages to install: ${packages[*]}"
        install_now=$(confirm "Install $group_name packages?" "Y")
    fi
    
    if [[ "$install_now" == "0" ]]; then
        log_warn "Skipping $group_name"
        return 0
    fi
    
    install_packages "${packages[@]}"
    log_info "$group_name installation complete"
}

list_groups() {
    echo "Available package groups:"
    echo

    if declare -p PACKAGE_GROUPS &>/dev/null; then
        # Manifest mode
        for group in "${!PACKAGE_GROUPS[@]}"; do
            echo "  $group"
            echo "    Description: ${GROUP_DESCRIPTIONS[$group]:-N/A}"
            echo "    Packages: ${PACKAGE_GROUPS[$group]}"
            echo "    Skip flag: SKIP_$(echo "$group" | tr '[:lower:]' '[:upper:]')"
            echo
        done
    else
        # Config mode fallback
        for group in "${!GROUPS[@]}"; do
            IFS=' ' read -r packages_var desc <<< "${GROUPS[$group]}"
            desc="${desc%\'}"
            desc="${desc#\'}"
            local packages=("${!packages_var[@]}")
            echo "  $group"
            echo "    Description: $desc"
            echo "    Packages: ${packages[*]:-N/A}"
            echo "    Skip flag: SKIP_$(echo "$group" | tr '[:lower:]' '[:upper:]')"
            echo
        done
    fi
}

process_package_groups() {
    local groups mode

    # Determine source of groups
    if declare -p PACKAGE_GROUPS &>/dev/null; then
        # Manifest mode
        groups=("${!PACKAGE_GROUPS[@]}")
        mode="manifest"
    else
        # Config mode fallback
        groups=("${!GROUPS[@]}")
        mode="config"
    fi

    log_info "Processing ${#groups[@]} package groups (mode: $mode)"

    for group in "${groups[@]}"; do
        local skip_var="SKIP_$(echo "$group" | tr '[:lower:]' '[:upper:]')"
        local skip_val="${!skip_var:-}"

        if [[ "$skip_val" == "true" ]]; then
            log_info "Skipping $group (flag: $skip_var=true)"
            continue
        fi

        local packages desc

        if [[ "$mode" == "manifest" ]]; then
            desc="${GROUP_DESCRIPTIONS[$group]:-$group}"
            packages=(${PACKAGE_GROUPS[$group]})
        else
            IFS=' ' read -r packages_var desc <<< "${GROUPS[$group]}"
            desc="${desc%\'}"
            desc="${desc#\'}"
            packages=("${!packages_var[@]}")
        fi

        if [[ ${#packages[@]} -eq 0 ]]; then
            log_warn "No packages defined for group '$group', skipping"
            continue
        fi

        install_tool_group "$desc" "${packages[@]}"
    done
}

validate_manifest() {
    if declare -p PACKAGE_GROUPS &>/dev/null; then
        for group in "${!PACKAGE_GROUPS[@]}"; do
            [[ -z "${GROUP_DESCRIPTIONS[$group]:-}" ]] && \
                log_warn "Group '$group' has no description"
            [[ -z "${PACKAGE_GROUPS[$group]}" ]] && \
                log_warn "Group '$group' has empty package list"
        done
    fi
}

generate_readme() {
    log_info "Generating README..."
    
    local readme_content="# Ghostarch: Custom Arch WSL2 with Selected BlackArch Tools

## Overview
Ghostarch is a streamlined setup for Arch Linux in WSL2, integrating selected bleeding-edge penetration testing tools from BlackArch without the full suite.

## User Configuration
- **User**: $TARGET_USER
- **Working Directory**: $WORKDIR

## Installation
1. Install Arch Linux in WSL2 using the official image.
2. Run \`./install-core.sh\` to set up zsh/oh-my-zsh and BlackArch repo.
3. Run \`./install-tools.sh\` to install tools and configure user.
4. (Optional) Run \`./install-nvidia.sh\` for GPU acceleration.
"
    
    echo "$readme_content" | sudo tee "$WORKDIR/README.md" > /dev/null
    sudo chown "$TARGET_USER:$TARGET_USER" "$WORKDIR/README.md"
}

main() {
    init_logging

    log_info "Starting Ghostarch Tools Installation"

    check_root
    check_wsl
    check_sudo
    
    # Load manifest or config
    if ! load_package_manifest; then
        log_debug "No manifest found, using config arrays"
        load_config
    fi

    if [[ "$LIST_GROUPS" == "true" ]]; then
        list_groups
        exit 0
    fi

    validate_manifest

    echo
    log_info "Ghostarch Tools Installation"
    echo "=============================="
    echo

    if [[ "${NONINTERACTIVE:-0}" != "1" ]]; then
        echo "This will install tools and configure your workspace."
        confirm "Continue?" "Y" || exit 0
    fi

    prompt_user_setup
    prompt_workdir_setup

    echo
    log_info "=== Installing Tools ==="

    process_package_groups

    generate_readme

    log_info "=== Tools Installation Complete ==="
    echo
    echo "Summary:"
    echo "  User: $TARGET_USER"
    echo "  Working Directory: $WORKDIR"
    echo
}

main "$@"
