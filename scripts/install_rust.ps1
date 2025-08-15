# Rust 1.89.0 安装脚本
Write-Host "Installing Rust 1.89.0"

# 如果存在rustup，先尝试卸载
if (Get-Command rustup -ErrorAction SilentlyContinue) {
    Write-Host "Uninstalling existing Rust installation..."
    rustup self uninstall -y
}

# 通过rustup安装指定版本的Rust
Write-Host "Downloading and installing Rust 1.89.0..."
$rustupUrl = "https://win.rustup.rs/x86_64"
Invoke-WebRequest -Uri $rustupUrl -OutFile "rustup-init.exe"
.\rustup-init.exe -y --default-toolchain 1.89.0 --profile minimal
Remove-Item .\rustup-init.exe

# 获取rustup环境
$env:PATH += ";$env:USERPROFILE\.cargo\bin"
# 刷新环境变量
$env:CARGO_HOME = "$env:USERPROFILE\.cargo"
$env:RUSTUP_HOME = "$env:USERPROFILE\.rustup"

# 验证安装
Write-Host "Rust version:"
rustc --version
Write-Host "Cargo version:"
cargo --version

# 确保使用正确的工具链
rustup default 1.89.0

Write-Host "Rust 1.89.0 installation completed"