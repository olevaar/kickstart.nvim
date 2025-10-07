#!/bin/bash
#
# Neovim Config Prerequisites Installation Script
#
# This script installs all the necessary dependencies for the kickstart.nvim configuration.
# It is intended to be idempotent and can be re-run without causing issues.

set -e # Exit immediately if a command exits with a non-zero status.
export DEBIAN_FRONTEND=noninteractive

# --- Helper Functions ---
print_info() {
  echo -e "\033[34m[INFO]\033[0m $1"
}

print_success() {
  echo -e "\033[32m[SUCCESS]\033[0m $1"
}

print_warning() {
  echo -e "\033[33m[WARNING]\033[0m $1"
}

print_error() {
  echo -e "\033[31m[ERROR]\033[0m $1"
  exit 1
}

command_exists() {
  command -v "$1" &>/dev/null
}

# --- Installation Functions ---

install_system_packages() {
  print_info "Installing essential system packages (curl, git, build-essential, unzip)..."
  if command_exists apt-get; then
    sudo apt-get update
    sudo apt-get install -y curl git build-essential unzip
  elif command_exists dnf; then
    sudo dnf install -y curl git gcc-c++ make unzip
  elif command_exists pacman; then
    sudo pacman -Syu --noconfirm curl git base-devel unzip
  else
    print_error "Unsupported package manager. Please install curl, git, build-essential, and unzip manually."
  fi
  print_success "Essential system packages installed."
}

install_fnm_and_node() {
  print_info "Installing fnm and Node.js v22..."
  if ! command_exists fnm; then
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
    export PATH="/home/$USER/.local/share/fnm:$PATH"
    eval "$(fnm env)"
    print_success "fnm installed."
  else
    print_info "fnm is already installed."
  fi

  if ! fnm list | grep -q "v22"; then
    fnm install 22
  fi
  fnm default 22
  print_success "Node.js v22 is set as the default."
}

install_npm_packages() {
  print_info "Installing global npm packages (markdownlint, @google/gemini-cli)..."
  npm install -g markdownlint @google/gemini-cli
  print_success "Global npm packages installed."
}

install_java_sdks() {
  print_info "Installing OpenJDK versions..."
  if command_exists apt-get; then
    sudo apt-get update
    sudo apt-get install -y openjdk-11-jdk openjdk-17-jdk openjdk-21-jdk
    print_success "OpenJDK 11, 17, and 21 installed."
  else
    print_warning "apt-get not found. Skipping OpenJDK installation. Please install them manually."
  fi
}

install_kotlin_sdk() {
    print_info "Installing SDKMAN! and Kotlin..."
    if [ ! -d "$HOME/.sdkman" ]; then
        curl -s "https://get.sdkman.io" | bash
        source "$HOME/.sdkman/bin/sdkman-init.sh"
    else
        source "$HOME/.sdkman/bin/sdkman-init.sh"
    fi

    sdk install kotlin
    print_success "Kotlin SDK installed via SDKMAN!."
}

install_kotlin_lsp() {
  print_info "Installing kotlin-lsp..."
  if [ ! -d "$HOME/kotlin-language-server" ]; then
    git clone https://github.com/fwcd/kotlin-language-server "$HOME/kotlin-language-server"
    cd "$HOME/kotlin-language-server"
    ./gradlew :server:installDist
    sudo ln -sf "$HOME/kotlin-language-server/server/build/install/server/bin/kotlin-language-server" /usr/local/bin/
    print_success "kotlin-lsp installed."
  else
    print_info "kotlin-lsp directory already exists. Skipping clone and build."
  fi
}

install_ripgrep_fd() {
  print_info "Installing ripgrep and fd-find..."
  if command_exists apt-get; then
    sudo apt-get install -y ripgrep fd-find
    # Create a symlink for fd, as the binary is often named fdfind on Debian-based systems
    if ! command_exists fd; then
      sudo ln -s $(which fdfind) /usr/local/bin/fd
    fi
  elif command_exists dnf; then
    sudo dnf install -y ripgrep fd-find
  elif command_exists pacman; then
    sudo pacman -S --noconfirm ripgrep fd
  else
    print_warning "Could not install ripgrep or fd-find with package manager. Please install them manually."
  fi
  print_success "ripgrep and fd-find installed."
}

install_nerd_font() {
  print_info "Installing Ubuntu Mono Nerd Font..."
  local font_dir="$HOME/.local/share/fonts"
  if [ ! -d "$font_dir/UbuntuMono" ]; then
    mkdir -p "$font_dir/UbuntuMono"
    cd "$font_dir/UbuntuMono"
    curl -fLo "Ubuntu Mono Nerd Font Complete.zip" https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/UbuntuMono.zip
    unzip "Ubuntu Mono Nerd Font Complete.zip"
    rm "Ubuntu Mono Nerd Font Complete.zip"
    fc-cache -fv
    print_success "Ubuntu Mono Nerd Font installed."
    print_success "You may now set your terminal font to 'Ubuntu Mono Nerd Font'. This will enhance the appearance of Neovim and its plugins."
  else
    print_info "Ubuntu Mono Nerd Font directory already exists. Skipping installation."
  fi
}

install_neovim() {
  print_info "Installing Neovim (>=0.11.x)..."
  if ! command_exists nvim || (command_exists nvim && ! nvim --version | head -n 1 | grep -q "0.1[1-9]"); then
    cd /tmp
    curl -fLo nvim.appimage https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
    chmod u+x nvim.appimage
    if [ ! -d "$HOME/.local/bin" ]; then
      mkdir -p "$HOME/.local/bin"
    fi
    sudo mv nvim.appimage /usr/local/bin/nvim
    print_success "Neovim AppImage installed to /usr/local/bin/nvim."
  else
    print_info "Neovim >=0.11.x is already installed."
  fi
}

install_win32yank() {
  print_info "Installing win32yank (for WSL clipboard integration)..."

  if ! grep -qi "microsoft" /proc/version 2>/dev/null; then
    print_info "Not running under WSL. Skipping win32yank. Consider installing wl-clipboard or xclip instead."
    return 0
  fi

  local bin_dir="$HOME/.local/bin"
  local exe_path="$bin_dir/win32yank.exe"
  local version="v0.1.1" 
  local zip_url="https://github.com/equalsraf/win32yank/releases/download/${version}/win32yank-x64.zip"

  if [ -f "$exe_path" ]; then
    print_info "win32yank already present at $exe_path"
    return 0
  fi

  mkdir -p "$bin_dir"
  tmp_zip="$(mktemp /tmp/win32yank.XXXXXX.zip)"
  print_info "Downloading $zip_url ..."
  curl -fsSL -o "$tmp_zip" "$zip_url" || print_error "Failed to download win32yank ZIP."

  print_info "Extracting win32yank.exe ..."
  if unzip -p "$tmp_zip" win32yank.exe > "$exe_path"; then
    chmod +x "$exe_path"
    rm -f "$tmp_zip"
    print_success "win32yank installed to $exe_path"
  else
    rm -f "$tmp_zip"
    print_error "Failed to extract win32yank.exe from ZIP."
  fi

  if [ -d "/usr/local/bin" ] && [ -w "/usr/local/bin" ]; then
    ln -sf "$exe_path" /usr/local/bin/win32yank.exe
  fi
}


install_linux_clipboard_tools() {
  print_info "Installing Linux clipboard tools (wl-clipboard/xclip)..."
  if command_exists apt-get; then
    sudo apt-get install -y wl-clipboard xclip
  elif command_exists dnf; then
    sudo dnf install -y wl-clipboard xclip
  elif command_exists pacman; then
    sudo pacman -S --noconfirm wl-clipboard xclip
  else
    print_warning "Could not install wl-clipboard or xclip automatically."
  fi
  print_success "Clipboard tools installed."
}

install_nvim_packages() {
    nvim --headless "+Lazy! sync" +qa
    nvim --headless "+MasonUpdate" +qa

    nvim --headless +"lua
    local pkgs = {
      'typescript-language-server',
      'angular-language-server',
      'jdtls',
      'eslint_d',
      'prettierd',
      'prettier', 
      'stylua',
    }
    local mr = require('mason-registry')
    mr.refresh()
    local targets = {}
    for _, name in ipairs(pkgs) do
      local ok, p = pcall(mr.get_package, name)
      if ok and not p:is_installed() then
        table.insert(targets, p)
      end
    end
    if #targets == 0 then
      return
    end
    local done = 0
    for _, p in ipairs(targets) do
      p:install():on('closed', function() done = done + 1 end)
    end
    vim.wait(600000, function() return done == #targets end, 200)
    " +qa
}


# --- Main Execution ---
main() {
  print_info "Starting Neovim prerequisites installation..."

  install_system_packages
  install_fnm_and_node
  install_npm_packages
  install_java_sdks
  install_kotlin_sdk
  install_kotlin_lsp
  install_ripgrep_fd
  install_nerd_font
  install_neovim
  install_win32yank
  install_linux_clipboard_tools
  install_nvim_packages

  print_success "All prerequisites have been installed successfully!"
  print_info "Please restart your shell or source your shell profile script (e.g., ~/.bashrc, ~/.zshrc) for all changes to take effect."
}

main
