#!/bin/bash

# Ghostarch Package Groups
# Group definitions and listing functions

# Package group mapping for DRY processing (config mode)
# Format: [group]="PACKAGES_VAR 'Description'"
declare -A GROUPS=(
    [networking]="NETWORKING_PACKAGES 'Networking Tools'"
    [programming]="PROGRAMMING_PACKAGES 'Programming Languages'"
    [pentest]="PENTEST_PACKAGES 'Pentest Tools'"
    [recon]="RECON_PACKAGES 'Recon Tools'"
    [additional]="ADDITIONAL_PACKAGES 'Additional Tools'"
)

list_groups() {
    echo "Available package groups:"
    echo

    if declare -p PACKAGE_GROUPS &>/dev/null; then
        for group in "${!PACKAGE_GROUPS[@]}"; do
            echo "  $group"
            echo "    Description: ${GROUP_DESCRIPTIONS[$group]:-N/A}"
            echo "    Packages: ${PACKAGE_GROUPS[$group]}"
            echo "    Skip flag: SKIP_$(echo "$group" | tr '[:lower:]' '[:upper:]')"
            echo
        done
    else
        for group in "${!GROUPS[@]}"; do
            IFS=' ' read -r packages_var desc <<<"${GROUPS[$group]}"
            desc="${desc%\"}"
            desc="${desc#\"}"
            local packages=("${!packages_var[@]}")
            echo "  $group"
            echo "    Description: $desc"
            echo "    Packages: ${packages[*]:-N/A}"
            echo "    Skip flag: SKIP_$(echo "$group" | tr '[:lower:]' '[:upper:]')"
            echo
        done
    fi
}

validate_manifest() {
    if declare -p PACKAGE_GROUPS &>/dev/null; then
        for group in "${!PACKAGE_GROUPS[@]}"; do
            [[ -z "${GROUP_DESCRIPTIONS[$group]:-}" ]] &&
                log_warn "Group '$group' has no description (consider adding to GROUP_DESCRIPTIONS)"
            [[ -z "${PACKAGE_GROUPS[$group]}" ]] &&
                log_warn "Group '$group' has empty package list"
        done
    fi
}
