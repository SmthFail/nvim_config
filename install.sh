#!/bin/bash

set -e


print_header() {
    echo "================================"
    echo "    Neovim Configuration Setup"
    echo "================================"
    echo
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

check_dep() {
    local cmd="$1"
    local pkg="$2"
    local desc="$3"

    if command_exists "$cmd"; then
        echo "  - $cmd: found ($desc)"
    else
        echo "  - $cmd: not found ($desc)"
        missing_system_deps+=("$pkg")
    fi
}

check_system_deps() {
    echo "System dependencies:"

    missing_system_deps=()

    check_dep gcc          build-essential   "Required for treesitter builds"
    check_dep make         make              "Required for some plugins"
    check_dep git          git               "Required for plugin management"
    check_dep rg           ripgrep           "Required for telescope live grep"
    check_dep curl         curl              "For download files"

    if [ "${#missing_system_deps[@]}" -gt 0 ]; then
        echo "To install missing system dependencies, run:"
        echo "  sudo apt install ${missing_system_deps[*]}"
        exit 1
    fi

    echo
}


check_tool() {
    local cmd="$1"
    local desc="$2"

    if command_exists "$cmd"; then
        local version_output
        version_output=$(command "$cmd" --version 2>&1) || version_output="(version unknown)"
        echo "  - $cmd: found ($version_output)"
    else
        echo "  - $cmd: not found$([[ -n "$desc" ]] && echo " ($desc)")"
    fi
}

check_config() {
    echo "Config & tool status:"

    # Проверяем конфиг вручную
    if [ -d "$HOME/.config/nvim" ]; then
        echo "  - Neovim config: found ($HOME/.config/nvim)"
    else
        echo "  - Neovim config: not found"
    fi

    # Check for Neovim itself
    if command_exists nvim; then
        echo "  - neovim: found ($(nvim --version | head -n 1))"
    else
        echo "  - neovim: not found (Required for this configuration)"
    fi

    # Проверяем инструменты
    check_tool uv
    check_tool ruff
    check_tool ty
    check_tool rust-analyzer
    check_tool lua-language-server

    echo
}

# Function to install config and LSP tools
install_config_lsp() {
    echo "Need root for some installation:"
    sudo -v

    # Reinstall neovim
    if command_exists nvim; then
        echo "Remove previous neovim..."
        sudo rm -rf /opt/nvim-linux-x86_64
    fi
    
    if ! curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz; then
        echo "Failed to download neovim" >%2
        exit 1
    fi
    sudo tar -C /opt -xzf nvim-linux-x86_64.tar.gz

    # check path to nvim in bashrc
    local path_entry='export PATH="$PATH:/opt/nvim-linux-x86_64/bin"'
    local bashrc_file="$HOME/.bashrc"

    if ! grep -Fq "$path_entry" "$bashrc_file"; then
        echo "$path_entry" >> "$bashrc_file"
        echo "Added '$path_entry' to $bashrc_file"
    else
        echo "'$path_entry' already exists in $bashrc_file"
    fi
    echo "Neovim installed"

    echo "Installing config files"
    if ! git clone https://github.com/SmthFail/nvim_config.git ~/.config/nvim; then
        echo "Can't clone config" >%2
        exit 1
    fi
    


    # Install uv if need. Not delete it
    if ! command_exists uv; then
        echo "uv not found. Install it"
        curl -LsSf https://astral.sh/uv/install.sh | sh
    fi

    # Install ruff and ty using uv
    uv tool install ruff@latest
    uv tool install ty@latest

    # Install rust analyzer
    if [ -f "$HOME/.local/bin/rust-analyzer" ]; then
        rm -rf ~/.local/bin/rust-analyzer
    fi
    echo "Installing rust-analyzer..."
    mkdir -p ~/.local/bin
    curl -L https://github.com/rust-lang/rust-analyzer/releases/latest/download/rust-analyzer-x86_64-unknown-linux-gnu.gz | gunzip -c - > ~/.local/bin/rust-analyzer
    chmod +x ~/.local/bin/rust-analyzer
    echo "rust-analyzer installed to ~/.local/bin/rust-analyzer"

    # Install lua-language-server. Due to apt installation we don't need to remove it
    echo "Install/udate lua server"
    sudo apt install -y lua-language-server
        
    echo
}

check_cancel() {
    local reply="$1"
    if [[ ! $reply =~ ^[Yy]$ ]]; then
        echo "Cancelled by user."
        exit 0
    fi
}


# Function to present options to user
handle_options() {
    echo "Installation options:"

    echo "1) Install/reinstall"
    echo "2) Update"
    echo "3) Delete all"
    echo "4) Quit installation"
    echo

    read -p "Select an option (1/2/3/4): " option
    echo

    case $option in
        1)
            read -p "It will remove all existing tools, config and neovim and reinstall it. Continue (Y/N)? " -n 1 -r
            echo
            check_cancel $REPLY
            echo "Installing/reinstalling all components..."
            install_config_lsp
            ;;
        2)
            read -p "It will update all installed tools, config and neovim. Continue (Y/N)? " -n 1 -r
            echo
            check_cancel $REPLY
            echo "Updating all installed dependencies... TODO"
            ;;
        3)
            read -p "It will delete all installed deps, config and neovim but not change system packages. Continue (Y/N)? " -n 1 -r
            echo
            check_cancel $REPLY
            
            echo "Deleting all installed components..."
            # Remove config
            if [ -d "$HOME/.config/nvim" ]; then
                echo "Removing Neovim configuration..."
                rm -rf "$HOME/.config/nvim"
                echo "Neovim configuration removed."
            fi

            # Remove LSP tools installed via uv
            if command_exists uv; then
                echo "Removing ruff and ty..."
                uv tool uninstall ruff || true
                uv tool uninstall ty || true
            else 
                echo "Can't uninstall ruff and ty. Uv not found"
            fi

            # Remove rust-analyzer
            if [ -f "$HOME/.local/bin/rust-analyzer" ]; then
                echo "Removing rust-analyzer..."
                rm -f "$HOME/.local/bin/rust-analyzer"
                echo "rust-analyzer removed."
            fi

            echo "All installed components have been removed. uv must be remove manual due to possible global installation"
            exit 0
            ;;
        4)
            echo "Installation cancelled by user."
            exit 0
            ;;
        *)
            echo "Invalid option selected."
            exit 1
            ;;
    esac
}


# Main execution
print_header
check_system_deps
check_config
handle_options


echo "Installation completed!"
echo
echo "To finish the setup, run: nvim"
echo "Neovim will automatically install plugins on first launch."

