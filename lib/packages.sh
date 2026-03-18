#!/bin/bash

# Ghostarch Package Functions
# Package installation, updates, and group handling

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

load_package_manifest() {
    local manifest_file="${PROJECT_ROOT}/package-groups.conf"
    if [[ -f "$manifest_file" ]]; then
        log_info "Loading package manifest from $manifest_file"
        # shellcheck disable=SC1090
        source "$manifest_file" || {
            log_error "Failed to load package manifest"
            return 1
        }
        if ! declare -p PACKAGE_GROUPS &>/dev/null; then
            log_error "Manifest does not define PACKAGE_GROUPS associative array"
            return 1
        fi
        log_info "Loaded ${#PACKAGE_GROUPS[@]} package groups from manifest"
        return 0
    fi
    return 1
}

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

process_package_groups() {
    local groups mode

    if declare -p PACKAGE_GROUPS &>/dev/null; then
        groups=("${!PACKAGE_GROUPS[@]}")
        mode="manifest"
    else
        groups=("${!GROUPS[@]}")
        mode="config"
    fi

    log_info "Processing ${#groups[@]} package groups (mode: $mode)"

    for group in "${groups[@]}"; do
        local skip_var
        skip_var="SKIP_$(echo "$group" | tr '[:lower:]' '[:upper:]')"
        local skip_val
        skip_val="${!skip_var:-}"

        if [[ "$skip_val" == "true" ]]; then
            log_info "Skipping $group (flag: $skip_var=true)"
            continue
        fi

        local packages desc

        if [[ "$mode" == "manifest" ]]; then
            desc="${GROUP_DESCRIPTIONS[$group]:-$group}"
            local pkg_list
            pkg_list="${PACKAGE_GROUPS[$group]}"
            read -ra packages <<<"$pkg_list"
        else
            IFS=' ' read -r packages_var desc <<<"${GROUPS[$group]}"
            desc="${desc%\"}"
            desc="${desc#\"}"
            packages=("${!packages_var[@]}")
        fi

        if [[ ${#packages[@]} -eq 0 ]]; then
            log_warn "No packages defined for group '$group', skipping"
            continue
        fi

        install_tool_group "$desc" "${packages[@]}"
    done
}
