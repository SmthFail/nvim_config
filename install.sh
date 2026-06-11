#!/usr/bin/env bash

set -euo pipefail

# ============================================================
# Neovim 0.12 Custom Environment Setup
# Safe for:
#   curl -fsSL https://raw.githubusercontent.com/SmthFail/nvim_config/main/install.sh | bash
# ============================================================

NVIM_VERSION="${NVIM_VERSION:-v0.12.3}"
NVIM_ARCHIVE="nvim-linux-x86_64.tar.gz"
NVIM_URL="https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/${NVIM_ARCHIVE}"

CONFIG_REPO="${CONFIG_REPO:-https://github.com/SmthFail/nvim_config.git}"
UV_INSTALL_URL="https://astral.sh/uv/install.sh"

RUST_ANALYZER_URL="https://github.com/rust-lang/rust-analyzer/releases/latest/download/rust-analyzer-x86_64-unknown-linux-gnu.gz"
LUALS_API_URL="https://api.github.com/repos/LuaLS/lua-language-server/releases/latest"

NVIM_CONFIG_DIR="$HOME/.config/nvim"
LOCAL_BIN="$HOME/.local/bin"

TMP_DIR=""

cleanup() {
    if [ -n "${TMP_DIR:-}" ] && [ -d "$TMP_DIR" ]; then
        rm -rf "$TMP_DIR"
    fi
}

trap cleanup EXIT

print_header() {
    echo "========================================="
    echo "    Neovim 0.12 Custom Environment Setup"
    echo "========================================="
    echo
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

require_tty() {
    if [ ! -r /dev/tty ]; then
        echo "Error: this installer needs an interactive terminal." >&2
        echo "Run it from a real terminal, not from a non-interactive shell." >&2
        exit 1
    fi
}

ask_yes_no() {
    local prompt="$1"
    local answer=""

    require_tty

    printf "%s [y/N]: " "$prompt" >/dev/tty
    read -r -n 1 answer </dev/tty
    printf "\n" >/dev/tty

    case "$answer" in
        y|Y)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

run_as_root() {
    if [ "${EUID:-$(id -u)}" -eq 0 ]; then
        "$@"
    else
        sudo "$@"
    fi
}

validate_sudo() {
    if [ "${EUID:-$(id -u)}" -ne 0 ]; then
        require_tty
        sudo -v </dev/tty
    fi
}

download_file() {
    local url="$1"
    local out="$2"

    curl -fL --retry 3 --retry-delay 2 "$url" -o "$out"
}

check_platform() {
    if [ "$(uname -s)" != "Linux" ]; then
        echo "Error: this script currently supports Linux only." >&2
        exit 1
    fi

    if [ "$(uname -m)" != "x86_64" ]; then
        echo "Error: this script currently supports x86_64 only." >&2
        echo "Detected architecture: $(uname -m)" >&2
        exit 1
    fi

    if ! command_exists apt || ! command_exists dpkg; then
        echo "Error: this installer currently expects a Debian/Ubuntu-like system with apt and dpkg." >&2
        exit 1
    fi
}

detect_existing_installations() {
    local found_any=false

    echo "Scanning system for existing installations..."

    if [ -d "$NVIM_CONFIG_DIR" ]; then
        echo "  [FOUND] Neovim configuration directory ($NVIM_CONFIG_DIR)"
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
        if ! ask_yes_no "Do you want to completely reinstall/upgrade them? Existing Neovim configuration will be overwritten"; then
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

    local deps=(
        ca-certificates
        curl
        gcc
        git
        gzip
        make
        ripgrep
        tar
    )

    local missing=()

    for pkg in "${deps[@]}"; do
        if ! dpkg -s "$pkg" >/dev/null 2>&1; then
            missing+=("$pkg")
        fi
    done

    validate_sudo

    if [ "${#missing[@]}" -gt 0 ]; then
        echo "Installing missing dependencies: ${missing[*]}"
        run_as_root apt update
        run_as_root apt install -y "${missing[@]}"
    else
        echo "All core dependencies present. Ensuring they are up to date..."
        run_as_root apt update
        run_as_root apt install -y --only-upgrade "${deps[@]}"
    fi

    echo
}

install_neovim() {
    echo "Installing Neovim ${NVIM_VERSION}..."

    local archive_path="$TMP_DIR/$NVIM_ARCHIVE"

    echo "Downloading Neovim binary archive:"
    echo "  $NVIM_URL"

    download_file "$NVIM_URL" "$archive_path"

    run_as_root rm -rf /opt/nvim-linux-x86_64
    run_as_root tar -C /opt -xzf "$archive_path"

    run_as_root mkdir -p /usr/local/bin
    run_as_root ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim

    echo "✓ Neovim installed to /usr/local/bin/nvim"
    echo
}

install_config() {
    echo "Syncing Neovim configuration repository..."

    if [ -d "$NVIM_CONFIG_DIR" ]; then
        local backup_dir
        backup_dir="$HOME/.config/nvim.backup.$(date +%Y%m%d_%H%M%S)"

        echo "Existing config found. Moving it to:"
        echo "  $backup_dir"

        mv "$NVIM_CONFIG_DIR" "$backup_dir"
    fi

    mkdir -p "$HOME/.config"

    if ! git clone --depth 1 "$CONFIG_REPO" "$NVIM_CONFIG_DIR"; then
        echo "Error: can't clone config repository:" >&2
        echo "  $CONFIG_REPO" >&2
        exit 1
    fi

    echo "✓ Configuration installed to $NVIM_CONFIG_DIR"
    echo
}

install_uv() {
    echo "Checking uv package manager..."

    mkdir -p "$LOCAL_BIN"
    export PATH="$LOCAL_BIN:$PATH"

    if ! command_exists uv; then
        echo "uv manager not found. Installing..."
        curl -LsSf "$UV_INSTALL_URL" | sh
        export PATH="$LOCAL_BIN:$PATH"
    else
        echo "uv already installed: $(command -v uv)"
    fi

    if ! command_exists uv; then
        echo "Error: uv was installed, but it is not available in PATH." >&2
        echo "Try opening a new shell or check $LOCAL_BIN." >&2
        exit 1
    fi

    echo "✓ uv available at $(command -v uv)"
    echo
}

install_python_tools() {
    echo "Installing/upgrading Python tools via uv..."

    uv tool install ruff@latest --force
    uv tool install ty@latest --force

    echo "✓ ruff and ty installed/upgraded"
    echo
}

install_rust_analyzer() {
    echo "Installing/upgrading rust-analyzer..."

    mkdir -p "$LOCAL_BIN"

    local tmp_ra="$TMP_DIR/rust-analyzer"
    local target_ra="$LOCAL_BIN/rust-analyzer"

    echo "Downloading rust-analyzer:"
    echo "  $RUST_ANALYZER_URL"

    curl -fL --retry 3 --retry-delay 2 "$RUST_ANALYZER_URL" | gunzip -c - > "$tmp_ra"
    chmod +x "$tmp_ra"

    mv "$tmp_ra" "$target_ra"

    export PATH="$LOCAL_BIN:$PATH"

    echo "✓ rust-analyzer installed to $target_ra"

    if command_exists rust-analyzer; then
        echo "  Active rust-analyzer: $(command -v rust-analyzer)"
    else
        echo "  Warning: rust-analyzer installed, but $LOCAL_BIN is not in PATH for this shell."
    fi

    echo
}

install_lua_language_server() {
    echo "Installing/upgrading lua-language-server..."

    local luals_url
    luals_url=$(
        curl -fsSL "$LUALS_API_URL" |
            grep -Eo 'https://[^"]+linux-x64\.tar\.gz' |
            head -n 1
    )

    if [ -z "$luals_url" ]; then
        echo "Error: failed to resolve lua-language-server download URL from GitHub API." >&2
        exit 1
    fi

    echo "Downloading lua-language-server:"
    echo "  $luals_url"

    local luals_tmp="$TMP_DIR/lua-language-server.tar.gz"
    download_file "$luals_url" "$luals_tmp"

    run_as_root rm -rf /opt/lua-language-server
    run_as_root mkdir -p /opt/lua-language-server
    run_as_root tar -xzf "$luals_tmp" -C /opt/lua-language-server

    run_as_root mkdir -p /usr/local/bin
    run_as_root ln -sf /opt/lua-language-server/bin/lua-language-server /usr/local/bin/lua-language-server

    echo "✓ lua-language-server installed to /usr/local/bin/lua-language-server"
    echo
}

print_final_message() {
    echo "========================================="
    echo "🎉 Setup completed successfully!"
    echo
    echo "Run:"
    echo "  nvim"
    echo
    echo "Then inside Neovim, run:"
    echo "  :checkhealth"
    echo "  :checkhealth vim.lsp"
    echo "  :packupdate"
    echo
    echo "If telescope-fzf-native is enabled, compile it once:"
    echo "  cd ~/.local/share/nvim/site/pack/core/opt/telescope-fzf-native.nvim && make"
    echo "========================================="
}

main() {
    print_header

    require_tty
    check_platform

    TMP_DIR="$(mktemp -d)"

    detect_existing_installations
    ensure_system_deps

    install_neovim
    install_config

    install_uv
    install_python_tools
    install_rust_analyzer
    install_lua_language_server

    print_final_message
}

main "$@"
