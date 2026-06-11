#!/bin/bash

set -e

print_header() {
    echo "========================================="
    echo "    Neovim 0.12 Custom Environment Setup"
    echo "========================================="
    echo
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

detect_existing_installations() {
    local found_any=false

    echo "Scanning system for existing installations..."

    if [ -d "$HOME/.config/nvim" ]; then
        echo "  [FOUND] Neovim configuration directory (~/.config/nvim)"
        found_any=true
    fi
    if command_exists nvim; then
        echo "  [FOUND] Neovim binary ($(command -v nvim))"
        found_any=true
    fi
    if command_exists rust-analyzer; then
        echo "  [FOUND] rust-analyzer ($(command -v rust-analyzer))"
        found_any=true
    fi
    if command_exists lua-language-server; then
        echo "  [FOUND] lua-language-server ($(command -v lua-language-server))"
        found_any=true
    fi
    if command_exists uv; then
        echo "  [FOUND] uv package manager ($(command -v uv))"
        found_any=true
    fi

    if [ "$found_any" = true ]; then
        echo
        echo "⚠️  WARNING: Some components are already present in your system."
        read -p "Do you want to completely reinstall/upgrade them? Existing configuration will be overwritten! (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Installation aborted by user."
            exit 0
        fi
    else
        echo "  No existing components found. Proceeding with clean install."
    fi
    echo
}

ensure_system_deps() {
    echo "Checking core system dependencies..."
    
    local deps=(gcc make git ripgrep curl)
    local missing=()

    for pkg in "${deps[@]}"; do
        if ! dpkg -s "$pkg" >/dev/null 2>&1; then
            missing+=("$pkg")
        fi
    done

    sudo -v

    if [ "${#missing[@]}" -gt 0 ]; then
        echo "Installing missing dependencies: ${missing[*]}"
        sudo apt update && sudo apt install -y "${missing[@]}"
    else
        echo "All core dependencies present. Ensuring they are up to date..."
        sudo apt update && sudo apt install -y --only-upgrade "${deps[@]}"
    fi
    echo
}

install_or_upgrade_environment() {
    # 1. Свежий Neovim (Переустановка)
    if [ -d "/opt/nvim-linux-x86_64" ]; then
        sudo rm -rf /opt/nvim-linux-x86_64
    fi
    echo "Downloading latest Neovim binary archive..."
    if ! curl -LO https://github.com; then
        echo "Error: Failed to download Neovim archive" >&2
        exit 1
    fi
    sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz
    rm nvim-linux-x86_64.tar.gz
    sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
    echo "✓ Neovim updated/installed to /usr/local/bin/nvim"

    echo "Syncing configuration repository..."
    rm -rf "$HOME/.config/nvim"
    if ! git clone https://github.com "$HOME/.config/nvim"; then
        echo "Error: Can't clone config repository" >&2
        exit 1
    fi

    if ! command_exists uv; then
        echo "uv manager not found. Installing..."
        curl -LsSf https://astral.sh | sh
    fi

    export PATH="$HOME/.local/bin:$PATH"

    echo "Upgrading tools via uv..."
    uv tool install ruff@latest --force
    uv tool install ty@latest --force

    local ra_path
    if command_exists rust-analyzer; then
        ra_path=$(command -v rust-analyzer)
        echo "Found existing rust-analyzer at: $ra_path. Updating it..."
    else
        echo "rust-analyzer not found. Setting default path to ~/.local/bin/rust-analyzer"
        mkdir -p "$HOME/.local/bin"
        ra_path="$HOME/.local/bin/rust-analyzer"
    fi

    if [ -w "$(dirname "$ra_path")" ]; then
        curl -L https://github.com | gunzip -c - > "$ra_path"
        chmod +x "$ra_path"
    else
        echo "Directory $(dirname "$ra_path") requires root privileges. Using sudo..."
        curl -L https://github.com | gunzip -c - > /tmp/rust-analyzer
        chmod +x /tmp/rust-analyzer
        sudo mv /tmp/rust-analyzer "$ra_path"
    fi
    echo "✓ rust-analyzer successfully updated at $ra_path"

    echo "Fetching latest release version for lua-language-server..."
    
    local luals_url
    luals_url=$(curl -s https://github.com | \
        grep -oP '"browser_download_url":\s*"\K[^"]+linux-x64\.tar\.gz' | head -n 1)

    if [ -z "$luals_url" ]; then
        echo "Error: Failed to resolve lua-language-server download URL from GitHub API." >&2
        exit 1
    fi

    echo "Downloading lua-language-server binary archive..."
    local luals_tmp="/tmp/lua-language-server.tar.gz"
    curl -L "$luals_url" -o "$luals_tmp"

    sudo rm -rf /opt/lua-language-server
    sudo mkdir -p /opt/lua-language-server
    sudo tar -xzf "$luals_tmp" -C /opt/lua-language-server
    rm -f "$luals_tmp"

    sudo ln -sf /opt/lua-language-server/bin/lua-language-server /usr/local/bin/lua-language-server
    echo "✓ lua-language-server successfully installed via prebuilt release to /usr/local/bin/lua-language-server"
    echo
}

print_header
detect_existing_installations
ensure_system_deps
install_or_upgrade_environment

echo "========================================="
echo "🎉 Setup completed successfully!"
echo "Run 'nvim' to initialize your environment."
echo "========================================="

