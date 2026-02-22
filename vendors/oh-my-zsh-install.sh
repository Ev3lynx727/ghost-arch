#!/bin/bash

# Vendored Oh-My-Zsh Installer
# Source this script to install Oh-My-Zsh locally
# This avoids remote code execution via curl | sh

set -euo pipefail

OH_MY_ZSH_REPO="https://github.com/ohmyzsh/ohmyzsh.git"
OH_MY_ZSH_BRANCH="master"

install_ohmyzsh() {
    local target_dir="${1:-$HOME/.oh-my-zsh}"
    local omz_branch="${2:-$OH_MY_ZSH_BRANCH}"

    if [[ -d "$target_dir" ]]; then
        echo "Oh-My-Zsh already installed at $target_dir"
        return 0
    fi

    echo "Installing Oh-My-Zsh to $target_dir..."

    git clone --depth 1 --branch "$omz_branch" "$OH_MY_ZSH_REPO" "$target_dir"

    if [[ ! -d "$target_dir" ]]; then
        echo "ERROR: Failed to install Oh-My-Zsh"
        return 1
    fi

    echo "Oh-My-Zsh installed successfully"

    return 0
}

install_ohmyzsh_plugins() {
    local omz_custom="${1:-$HOME/.oh-my-zsh/custom}"

    mkdir -p "$omz_custom/plugins"

    local plugins=(
        "zsh-users/zsh-autosuggestions"
        "zsh-users/zsh-syntax-highlighting"
    )

    for plugin in "${plugins[@]}"; do
        local plugin_name="${plugin##*/}"
        local plugin_path="$omz_custom/plugins/$plugin_name"

        if [[ -d "$plugin_path" ]]; then
            echo "Plugin $plugin_name already installed, skipping..."
            continue
        fi

        echo "Installing plugin: $plugin_name"
        git clone --depth 1 "https://github.com/$plugin.git" "$plugin_path" 2>/dev/null || true
    done

    return 0
}

setup_ohmyzsh_unattended() {
    local target_dir="${1:-$HOME/.oh-my-zsh}"

    local zshrc_template="$target_dir/templates/zshrc.zsh-template"
    local zshrc_backup="$target_dir/.zshrc.backup"
    local user_zshrc="$HOME/.zshrc"

    if [[ ! -f "$zshrc_template" ]]; then
        echo "ERROR: zshrc template not found"
        return 1
    fi

    if [[ -f "$user_zshrc" ]]; then
        cp "$user_zshrc" "$zshrc_backup"
        echo "Backed up existing .zshrc to $zshrc_backup"
    fi

    cp "$zshrc_template" "$user_zshrc"
    echo "Created new .zshrc from template"

    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_ohmyzsh "$@"
fi
