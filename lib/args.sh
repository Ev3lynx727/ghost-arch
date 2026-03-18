#!/bin/bash

# Ghostarch Argument Parsing
# Command-line argument handling

export SKIP_NETWORKING=false
export SKIP_PROGRAMMING=false
export SKIP_PENTEST=false
export SKIP_RECON=false
export SKIP_ADDITIONAL=false
export SKIP_USER=false
export SKIP_WORKDIR=false
export LIST_GROUPS=false

usage() {
    cat <<EOF
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

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
        -h | --help) usage ;;
        -n | --noninteractive) export NONINTERACTIVE=1 ;;
        -d | --debug) export DEBUG=1 ;;
        -l | --list-groups) export LIST_GROUPS=true ;;
        --skip-networking) export SKIP_NETWORKING=true ;;
        --skip-programming) export SKIP_PROGRAMMING=true ;;
        --skip-pentest) export SKIP_PENTEST=true ;;
        --skip-recon) export SKIP_RECON=true ;;
        --skip-additional) export SKIP_ADDITIONAL=true ;;
        --skip-user) export SKIP_USER=true ;;
        --skip-workdir) export SKIP_WORKDIR=true ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
        esac
        shift
    done
}
