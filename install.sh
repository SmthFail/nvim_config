#!/bin/bash

set -e

# Function to print status messages
print_status() {
    echo "[INFO] $1"
}

print_success() {
    echo "[SUCCESS] $1"
}

print_warning() {
    echo "[WARNING] $1"
}

print_error() {
    echo "[ERROR] $1"
}

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

# Function to check previous installation
check_previous_installation() {
    echo "Checking for previous installations..."

    # Check if neovim config exists
    if [ -d "$HOME/.config/nvim" ]; then
        print_warning "Neovim configuration already exists at $HOME/.config/nvim"
        read -p "Do you want to continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_error "Installation cancelled by user."
            exit 1
        fi
    else
        print_status "No previous Neovim configuration found."
    fi

    # Check for installed LSP tools
    echo
    print_status "Checking for installed LSP tools:"

    # Check for uv
    if command_exists uv; then
        print_warning "uv is already installed: $(uv --version)"
    else
        print_status "uv is not installed"
    fi

    # Check for ruff
    if command_exists ruff; then
        print_warning "ruff is already installed: $(ruff --version)"
    else
        print_status "ruff is not installed"
    fi

    # Check for ty
    if command_exists ty; then
        print_warning "ty is already installed: $(ty --version 2>/dev/null || echo 'installed but not working')"
    else
        print_status "ty is not installed"
    fi

    # Check for rust-analyzer
    if command_exists rust-analyzer; then
        print_warning "rust-analyzer is already installed: $(rust-analyzer --version 2>/dev/null || echo 'installed but not working')"
    else
        print_status "rust-analyzer is not installed"
    fi

    # Check for lua-language-server
    if command_exists lua-language-server; then
        print_warning "lua-language-server is already installed"
    else
        print_status "lua-language-server is not installed"
    fi

    echo
}

# Function to identify dependencies
identify_dependencies() {
    echo "Identifying required dependencies..."
    echo

    print_status "Required packages for Neovim plugins:"

    # Dependencies for telescope
    if command_exists rg; then
        print_success "ripgrep (rg) is installed"
    else
        print_error "ripgrep (rg) is NOT installed - Required for telescope live grep"
    fi

    if command_exists fd; then
        print_success "fd is installed"
    else
        print_error "fd is NOT installed - Recommended for telescope file finding"
    fi

    # Dependencies for treesitter
    if command_exists gcc; then
        print_success "gcc is installed - Required for treesitter builds"
    else
        print_error "gcc is NOT installed - Required for treesitter builds"
    fi

    if command_exists make; then
        print_success "make is installed - Required for some plugins"
    else
        print_error "make is NOT installed - Required for some plugins"
    fi

    # Git is required for lazy.nvim
    if command_exists git; then
        print_success "git is installed - Required for plugin management"
    else
        print_error "git is NOT installed - Required for plugin management"
    fi

    # Check for Neovim itself
    if command_exists nvim; then
        print_success "neovim is installed: $(nvim --version | head -n 1)"
    else
        print_error "neovim is NOT installed - Required for this configuration"
    fi

    echo
}

# Function to install dependencies
install_dependencies() {
    echo "Installing required dependencies..."
    echo

    # Update package list
    sudo apt update

    # Install packages
    packages_to_install=()

    if ! command_exists nvim; then
        packages_to_install+=("neovim")
        print_status "Will install neovim"
    fi

    if ! command_exists rg; then
        packages_to_install+=("ripgrep")
        print_status "Will install ripgrep"
    fi

    if ! command_exists fd; then
        packages_to_install+=("fd-find")
        print_status "Will install fd-find"
    fi

    if ! command_exists gcc; then
        packages_to_install+=("build-essential")
        print_status "Will install build-essential"
    fi

    if ! command_exists git; then
        packages_to_install+=("git")
        print_status "Will install git"
    fi

    if [ ${#packages_to_install[@]} -gt 0 ]; then
        print_status "Installing packages: ${packages_to_install[*]}"
        sudo apt install -y "${packages_to_install[@]}"
    else
        print_success "All required packages are already installed!"
    fi

    echo
}

# Function to install LSP tools
install_lsp_tools() {
    echo "Installing LSP tools..."
    echo

    # Install uv if not present
    if ! command_exists uv; then
        print_status "Installing uv..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
        # Reload shell to get uv in PATH
        source "$HOME/.cargo/env" 2>/dev/null || true
        export PATH="$HOME/.cargo/bin:$PATH"
    else
        print_success "uv is already installed"
    fi

    # Install ruff and ty using uv
    print_status "Installing ruff and ty..."
    uv tool install ruff@latest
    uv tool install ty@latest

    # Install rust analyzer if not present
    if ! command_exists rust-analyzer; then
        print_status "Installing rust-analyzer..."
        mkdir -p ~/.local/bin
        curl -L https://github.com/rust-lang/rust-analyzer/releases/latest/download/rust-analyzer-x86_64-unknown-linux-gnu.gz | gunzip -c - > ~/.local/bin/rust-analyzer
        chmod +x ~/.local/bin/rust-analyzer
        print_success "rust-analyzer installed to ~/.local/bin/rust-analyzer"
    else
        print_success "rust-analyzer is already installed"
    fi

    # Install lua-language-server if not present
    if ! command_exists lua-language-server; then
        print_status "Installing lua-language-server..."
        sudo apt install -y lua-language-server
        if ! command_exists lua-language-server; then
            print_warning "Could not install lua-language-server via apt, installing via snap..."
            if command_exists snap; then
                sudo snap install lua-language-server
            else
                print_error "Cannot install lua-language-server: neither apt nor snap available"
            fi
        fi
    else
        print_success "lua-language-server is already installed"
    fi

    echo
}

# Main execution
main() {
    print_header

    check_previous_installation
    identify_dependencies

    echo "This script will now install the missing dependencies."
    read -p "Do you want to proceed with installation? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        print_error "Installation cancelled by user."
        exit 1
    fi

    install_dependencies
    install_lsp_tools

    print_success "Installation completed!"
    echo
    print_status "To finish the setup, run: nvim"
    print_status "Neovim will automatically install plugins on first launch."
}

# Run main function
main "$@"

