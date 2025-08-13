#!/bin/bash

set -e

echo "Installing Rust 1.89.0"

#卸载可能存在的旧版本
if command -v rustup &> /dev/null; then
    echo "Uninstalling existing Rust installation..."
    rustup self uninstall -y || true
fi

#通过rustup安装指定版本的Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain 1.89.0 --profile minimal

#获取rustup环境
source "$HOME/.cargo/env"

#验证安装
echo "Rust version:"
rustc --version
echo "Cargo version:"
cargo --version

#确保使用正确的工具链
rustup default 1.89.0

echo "Rust 1.89.0 installation completed"