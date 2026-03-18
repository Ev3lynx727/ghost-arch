#!/bin/bash

# Ghostarch Common Library
# Core utilities: logging, configuration, and error handling

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

# Source module libraries
# shellcheck disable=SC1091,SC2086
source "${SCRIPT_DIR}/system.sh" || exit 1
source "${SCRIPT_DIR}/packages.sh" || exit 1
source "${SCRIPT_DIR}/prompts.sh" || exit 1
source "${SCRIPT_DIR}/args.sh" || exit 1
source "${SCRIPT_DIR}/groups.sh" || exit 1
source "${SCRIPT_DIR}/readme.sh" || exit 1
source "${SCRIPT_DIR}/zsh.sh" || exit 1

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    local level="$1"
    shift
    local msg="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    case "$level" in
    INFO) echo -e "${GREEN}[INFO]${NC} $msg" ;;
    WARN) echo -e "${YELLOW}[WARN]${NC} $msg" ;;
    ERROR) echo -e "${RED}[ERROR]${NC} $msg" ;;
    DEBUG) [[ "${DEBUG:-0}" == "1" ]] && echo -e "${BLUE}[DEBUG]${NC} $msg" ;;
    esac

    echo "[$timestamp] [$level] $msg" >>"$LOG_FILE" 2>/dev/null || true
}

log_info() { log "INFO" "$@"; }
log_warn() { log "WARN" "$@"; }
log_error() { log "ERROR" "$@"; }
log_debug() { log "DEBUG" "$@"; }

init_logging() {
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    chmod 644 "$LOG_FILE" 2>/dev/null || true
    log_info "Ghostarch v${GHOSTARCH_VERSION} installation started"
}

load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        log_info "Loading configuration from $CONFIG_FILE"
        # shellcheck disable=SC1090
        source "$CONFIG_FILE"
    else
        log_warn "Config file not found, using defaults"
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
