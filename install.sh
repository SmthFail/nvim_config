#!/bin/bash

set -e

echo "Install uv"
curl -LsSf https://astral.sh/uv/install.sh | sh

echo "Install ruff and ty"
uv tool install ruff@latest
uv tool install ty@latest

echo "Install rust analyzer"
mkdir -p ~/.local/bin
curl -L https://github.com/rust-lang/rust-analyzer/releases/latest/download/rust-analyzer-x86_64-unknown-linux-gnu.gz | gunzip -c - > ~/.local/bin/rust-analyzer
chmod +x ~/.local/bin/rust-analyzer

