#!/bin/bash
#
# Neovim Config Prerequisites Installation Script
#
# This script installs all the necessary dependencies for the kickstart.nvim configuration.

set -e # Exit immediately if a command exits with a non-zero status.
export DEBIAN_FRONTEND=noninteractive

# --- Global Variables ---
OS=""

# --- Helper Functions ---
print_info() {
  echo -e "\033[34m[INFO]\033[0m $*"
}

print_success() {
  echo -e "\033[32m[SUCCESS]\033[0m $*"
}

print_warning() {
  echo -e "\033[33m[WARNING]\033[0m $*"
}

print_error() {
  echo -e "\033[31m[ERROR]\033[0m $*" >&2
  exit 1
}

command_exists() {
  command -v "$1" &>/dev/null
}

detect_os() {
  print_info "Detecting operating system..."
  case "$(uname -s)" in
  Linux*) OS="linux" ;;
  Darwin*) OS="macos" ;;
  *) print_error "Unsupported operating system: $(uname -s)" ;;
  esac
  print_success "Operating system detected: $OS"
}

# --- Installation Functions ---

install_system_packages() {
  print_info "Installing essential system packages..."
  case "$OS" in
  "linux")
    if command_exists apt-get; then
      sudo apt-get update
      sudo apt-get install -y curl git build-essential unzip
    elif command_exists dnf; then
      sudo dnf install -y curl git gcc-c++ make unzip
    elif command_exists pacman; then
      sudo pacman -Syu --noconfirm curl git base-devel unzip
    else
      print_error "Unsupported Linux package manager. Please install curl, git, build-essential, and unzip manually."
    fi
    ;;
  "macos")
    if ! command_exists brew; then
      print_error "Homebrew not found. Please install Homebrew first: https://brew.sh/"
    fi
    brew install curl git unzip make
    ;;
  esac
  print_success "Essential system packages installed."
}

install_fnm_and_node() {
  print_info "Installing fnm and Node.js v22..."
  if ! command_exists fnm; then
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
    export PATH="$HOME/.local/share/fnm:$PATH"
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
  # Language servers from npm get installed by Mason, so we only install what mason doesn't cover
  print_info "Installing global npm packages (markdownlint, @google/gemini-cli)..."
  npm install -g markdownlint-cli @google/gemini-cli
  print_success "Global npm packages installed."
}

install_java_sdks() {
  print_info "Installing OpenJDK versions..."

  _install_java_with_sdkman() {
    if [ ! -d "$HOME/.sdkman" ]; then
      print_info "Installing SDKMAN! to manage Java versions..."
      curl -s "https://get.sdkman.io" | bash
    fi
    source "$HOME/.sdkman/bin/sdkman-init.sh"
    print_info "Installing Java $1 via SDKMAN!..."
    sdk install java "$1"
  }

  case "$OS" in
  "linux")
    if command_exists apt-get; then
      sudo apt-get update
      print_info "Attempting to install OpenJDK 11 with apt..."
      if ! sudo apt-get install -y openjdk-11-jdk; then
        print_warning "openjdk-11-jdk not available via apt, falling back to SDKMAN!."
        _install_java_with_sdkman "11.0.23-tem"
      fi
      print_info "Attempting to install OpenJDK 17 with apt..."
      if ! sudo apt-get install -y openjdk-17-jdk; then
        print_warning "openjdk-17-jdk not available via apt, falling back to SDKMAN!."
        _install_java_with_sdkman "17.0.11-tem"
      fi
      print_info "Attempting to install OpenJDK 21 with apt..."
      if ! sudo apt-get install -y openjdk-21-jdk; then
        print_warning "openjdk-21-jdk not available via apt, falling back to SDKMAN!."
        _install_java_with_sdkman "21.0.3-tem"
      fi
      print_success "OpenJDK installation process completed."
    else
      print_warning "apt-get not found. Using SDKMAN! to install Java versions."
      _install_java_with_sdkman "11.0.23-tem"
      _install_java_with_sdkman "17.0.11-tem"
      _install_java_with_sdkman "21.0.3-tem"
      print_success "OpenJDK installation process completed."
    fi
    ;;
  "macos")
    if ! command_exists brew; then
      print_error "Homebrew not found. Please install Homebrew first."
    fi
    brew install openjdk@11 openjdk@17 openjdk@21
    print_success "OpenJDK 11, 17, and 21 installed via Homebrew."
    ;;
  esac
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
  print_info "Installing ripgrep and fd..."
  case "$OS" in
  "linux")
    if command_exists apt-get; then
      sudo apt-get install -y ripgrep fd-find
      if ! command_exists fd; then
        sudo ln -s $(which fdfind) /usr/local/bin/fd
      fi
    elif command_exists dnf; then
      sudo dnf install -y ripgrep fd-find
    elif command_exists pacman; then
      sudo pacman -S --noconfirm ripgrep fd
    else
      print_warning "Could not install ripgrep or fd with package manager. Please install them manually."
    fi
    ;;
  "macos")
    if ! command_exists brew; then
      print_error "Homebrew not found. Please install Homebrew first."
    fi
    brew install ripgrep fd
    ;;
  esac
  print_success "ripgrep and fd installed."
}

install_nerd_font() {
  print_info "Installing Ubuntu Mono Nerd Font..."
  local font_dir
  case "$OS" in
  "linux")
    font_dir="$HOME/.local/share/fonts"
    ;;
  "macos")
    font_dir="$HOME/Library/Fonts"
    ;;
  esac

  if [ ! -d "$font_dir" ]; then
    mkdir -p "$font_dir"
  fi

  if [ ! -f "$font_dir/UbuntuMonoNerdFont-Regular.ttf" ]; then
    cd /tmp
    curl -fLo "UbuntuMono.zip" https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/UbuntuMono.zip
    unzip -o "UbuntuMono.zip" -d "$font_dir"
    rm "UbuntuMono.zip"

    if [ "$OS" = "linux" ]; then
      fc-cache -fv
    fi

    print_success "Ubuntu Mono Nerd Font installed."
    print_success "You may now set your terminal font to 'Ubuntu Mono Nerd Font'. This will enhance the appearance of Neovim and its plugins."
    if [ "$OS" = "linux" ] && grep -qi "microsoft" /proc/version 2>/dev/null; then
      print_success "If you are using WSL, you will need to download the font on your Windows host and set it in your terminal emulator. Go to https://nerdfonts.com/font-downloads to download the font. (You can choose any Nerd Font you like!, this script just installs Ubuntu Mono)"
    fi
  else
    print_info "Ubuntu Mono Nerd Font already installed. Skipping installation."
  fi
}

install_neovim() {
  print_info "Installing Neovim (latest stable)..."
  case "$OS" in
  "linux")
    if ! command_exists nvim || (command_exists nvim && ! nvim --version | head -n 1 | grep -q "0.1[0-9]"); then
      cd /tmp
      curl -fLo nvim.appimage https://github.com/neovim/neovim/releases/download/v0.11.4/nvim-linux-x86_64.appimage
      chmod u+x nvim.appimage
      if [ ! -d "$HOME/.local/bin" ]; then
        mkdir -p "$HOME/.local/bin"
      fi
      if sudo mv nvim.appimage /usr/local/bin/nvim; then
        print_success "Neovim AppImage installed to /usr/local/bin/nvim."
      else
        mv nvim.appimage "$HOME/.local/bin/nvim"
        print_success "Neovim AppImage installed to $HOME/.local/bin/nvim."
        print_warning "Make sure $HOME/.local/bin is in your PATH."
      fi
    else
      print_info "Neovim is already installed."
    fi
    ;;
  "macos")
    if ! command_exists brew; then
      print_error "Homebrew not found. Please install Homebrew first."
    fi
    brew install neovim
    print_success "Neovim installed via Homebrew."
    ;;
  esac
}

install_win32yank() {
  if [ "$OS" != "linux" ] || ! grep -qi "microsoft" /proc/version 2>/dev/null; then
    print_info "Not running under WSL. Skipping win32yank."
    return 0
  fi

  print_info "Installing win32yank (for WSL clipboard integration)..."
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
  if unzip -p "$tmp_zip" win32yank.exe >"$exe_path"; then
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

install_clipboard_tools() {
  if [ "$OS" = "macos" ]; then
    print_info "macOS has built-in clipboard tools (pbcopy/pbpaste). Skipping installation."
    return 0
  fi

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

install_fuse() {
  if [ "$OS" != "linux" ]; then
    print_info "Not running on Linux. Skipping fuse installation."
    return 0
  fi

  print_info "Installing fuse (for AppImage support)..."
  if command_exists apt-get; then
    sudo apt-get install -y fuse
  elif command_exists dnf; then
    sudo dnf install -y fuse
  elif command_exists pacman; then
    sudo pacman -S --noconfirm fuse2
  else
    print_warning "Could not install fuse automatically. Please install it manually if you intend to use AppImages."
  fi
  print_success "Fuse installed."
}

install_nvim_packages() {
  print_info "Installing Neovim plugins and Mason packages..."
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
      print('All Mason packages are already installed.')
      return
    end
    print('Installing ' .. #targets .. ' Mason package(s)...')
    local done = 0
    for _, p in ipairs(targets) do
      p:install():on('closed', function() done = done + 1 end)
    end
    vim.wait(600000, function() return done == #targets end, 200)
    print('Mason package installation complete.')
    " +qa
  print_success "Neovim setup complete."
}

# --- Main Execution ---
main() {
  detect_os
  print_info "Starting Neovim prerequisites installation for $OS..."

  install_system_packages
  install_fnm_and_node
  install_npm_packages
  install_java_sdks
  install_kotlin_sdk
  install_kotlin_lsp
  install_ripgrep_fd
  install_nerd_font
  install_fuse
  install_neovim
  install_win32yank
  install_clipboard_tools
  install_nvim_packages

  print_success "All prerequisites have been installed successfully!"
  print_info "Please restart your shell or source your shell profile script (e.g., ~/.bashrc, ~/.zshrc) for all changes to take effect."
}

main
