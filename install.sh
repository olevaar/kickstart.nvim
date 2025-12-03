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

get_latest_github_release() {
  local repo="$1"
  curl -s "https://api.github.com/repos/${repo}/releases/latest" | grep '"tag_name"' | cut -d '"' -f 4
}

check_sudo() {
  if ! command_exists sudo; then
    print_error "sudo is required but not installed. Please install sudo or run this script as root."
  fi
  if ! sudo -n true 2>/dev/null; then
    print_info "This script requires sudo privileges. You may be prompted for your password."
    sudo -v || print_error "Failed to obtain sudo privileges."
  fi
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
    check_sudo
    if command_exists apt-get; then
      sudo apt-get update
      sudo apt-get install -y curl git build-essential unzip python3 python3-pip python3-venv pipx
    elif command_exists dnf; then
      sudo dnf install -y curl git gcc-c++ make unzip python3 python3-pip pipx
    elif command_exists pacman; then
      sudo pacman -Syu --noconfirm curl git base-devel unzip python python-pip python-pipx
    else
      print_error "Unsupported Linux package manager. Please install curl, git, build-essential, unzip, python3, and pipx manually."
    fi
    ;;
  "macos")
    if ! command_exists brew; then
      print_error "Homebrew not found. Please install Homebrew first: https://brew.sh/"
    fi
    brew install curl git unzip make python pipx
    ;;
  esac
  print_success "Essential system packages installed."
}

install_node() {
  print_info "Installing Node.js v22..."

  if command_exists mise; then
    print_info "mise detected. Using mise to install Node.js..."
    if ! mise list node 2>/dev/null | grep -q "22"; then
      mise install node@22
    fi
    mise use -g node@22
    print_success "Node.js v22 installed and set as default via mise."
    return
  fi

  print_info "mise not found. Installing fnm and Node.js v22..."
  if ! command_exists fnm; then
    curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
    export PATH="$HOME/.local/share/fnm:$PATH"
    eval "$(fnm env)"
    print_success "fnm installed."
    setup_fnm_shell
  else
    print_info "fnm is already installed."
    setup_fnm_shell
  fi

  if ! fnm list | grep -q "v22"; then
    fnm install 22
  fi
  fnm default 22
  print_success "Node.js v22 is set as the default."
}

setup_fnm_shell() {
  print_info "Configuring shell for fnm..."
  local profile_file
  local shell_name
  shell_name=$(basename "$SHELL")

  case "$shell_name" in
  "bash") profile_file="$HOME/.bashrc" ;;
  "zsh") profile_file="$HOME/.zshrc" ;;
  "fish") profile_file="$HOME/.config/fish/config.fish" ;;
  *)
    print_warning "Could not detect shell ($shell_name). Please add fnm to your shell profile manually."
    print_warning "Add the following lines to your shell configuration file:"
    print_warning "For bash/zsh: "
    print_warning "  export PATH=\"\$HOME/.local/share/fnm:\$PATH\""
    print_warning "  eval \"\$(fnm env)\""
    print_warning "For fish: "
    print_warning "  fish_add_path \"\$HOME/.local/share/fnm\""
    print_warning "  fnm env | source"
    return
    ;;
  esac

  if [ ! -f "$profile_file" ]; then
    print_info "Creating shell profile file: $profile_file"
    touch "$profile_file"
  fi

  local fnm_path_str="export PATH=\"\$HOME/.local/share/fnm:\$PATH\""
  local fnm_env_str="eval \"\$(fnm env)\""

  if [ "$shell_name" = "fish" ]; then
    fnm_path_str="fish_add_path \"\$HOME/.local/share/fnm\""
    fnm_env_str="fnm env | source"
  fi

  if ! grep -q "fnm env" "$profile_file"; then
    print_info "Adding fnm configuration to $profile_file"
    echo "" >>"$profile_file"
    echo "# fnm (Fast Node Manager)" >>"$profile_file"
    echo "$fnm_path_str" >>"$profile_file"
    echo "$fnm_env_str" >>"$profile_file"
    print_success "fnm configured in $profile_file."
  else
    print_info "fnm configuration already present in $profile_file."
  fi
}

install_python() {
  print_info "Installing Python..."

  if command_exists mise; then
    print_info "mise detected. Using mise to install Python 3.12..."
    if ! mise list python 2>/dev/null | grep -q "3.12"; then
      mise install python@3.12
    fi
    mise use -g python@3.12
    print_success "Python 3.12 installed and set as default via mise."
    return
  fi

  print_info "mise not found. Python should already be installed via system packages."
}

install_python_packages() {
  print_info "Installing Python packages via pipx (mdformat)..."
  if ! command_exists pipx; then
    print_error "pipx not found. Please ensure system packages are installed correctly."
  fi

  pipx ensurepath
  if ! pipx install mdformat; then
    print_warning "Failed to install mdformat via pipx."
  fi
  print_success "Python packages installed."
}

install_npm_packages() {
  # Language servers from npm get installed by Mason, so we only install what mason doesn't cover
  print_info "Installing global npm packages (markdownlint, @google/gemini-cli)..."
  if ! npm install -g markdownlint-cli @google/gemini-cli; then
    print_error "Failed to install npm packages. Please check your npm installation."
  fi
  print_success "Global npm packages installed."
}

install_java_sdks() {
  print_info "Installing OpenJDK versions..."

  if command_exists mise; then
    print_info "mise detected. Using mise to install Java versions..."
    for version in 11 17 21; do
      if ! mise list java 2>/dev/null | grep -q "^java.*${version}"; then
        mise install java@${version}
      fi
    done
    mise use -g java@21
    print_success "Java 11, 17, and 21 installed via mise (default: 21)."
    return
  fi

  _install_java_with_sdkman() {
    if [ ! -d "$HOME/.sdkman" ]; then
      print_info "Installing SDKMAN! to manage Java versions..."
      curl -s "https://get.sdkman.io" | bash
      if [ ! -f "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
        print_error "SDKMAN! installation failed."
      fi
    fi
    if ! source "$HOME/.sdkman/bin/sdkman-init.sh"; then
      print_error "Failed to initialize SDKMAN!."
    fi
    print_info "Installing Java $1 via SDKMAN!..."
    if ! sdk install java "$1"; then
      print_warning "Failed to install Java $1 via SDKMAN!."
    fi
  }

  case "$OS" in
  "linux")
    if command_exists apt-get; then
      check_sudo
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
    if [ ! -f "$HOME/.sdkman/bin/sdkman-init.sh" ]; then
      print_error "SDKMAN! installation failed."
    fi
  fi

  if ! source "$HOME/.sdkman/bin/sdkman-init.sh"; then
    print_error "Failed to initialize SDKMAN!."
  fi

  if ! sdk install kotlin; then
    print_warning "Failed to install Kotlin SDK via SDKMAN!."
  fi
  print_success "Kotlin SDK installed via SDKMAN!."
}

install_kotlin_lsp() {
  print_info "Installing kotlin-lsp..."
  if [ ! -d "$HOME/kotlin-language-server" ]; then
    local original_dir="$PWD"
    git clone https://github.com/fwcd/kotlin-language-server "$HOME/kotlin-language-server"
    cd "$HOME/kotlin-language-server" || print_error "Failed to change directory to $HOME/kotlin-language-server"

    if [ ! -f "./gradlew" ]; then
      cd "$original_dir"
      print_error "gradlew not found in kotlin-language-server repository."
    fi

    if ! ./gradlew :server:installDist; then
      cd "$original_dir"
      print_error "Failed to build kotlin-language-server."
    fi

    check_sudo
    if ! sudo ln -sf "$HOME/kotlin-language-server/server/build/install/server/bin/kotlin-language-server" /usr/local/bin/; then
      print_warning "Failed to create symlink in /usr/local/bin. You may need to add $HOME/kotlin-language-server/server/build/install/server/bin to your PATH."
    fi

    cd "$original_dir"
    print_success "kotlin-lsp installed."
  else
    print_info "kotlin-lsp directory already exists. Skipping clone and build."
  fi
}

install_ripgrep_fd() {
  print_info "Installing ripgrep and fd..."
  case "$OS" in
  "linux")
    check_sudo
    if command_exists apt-get; then
      sudo apt-get install -y ripgrep fd-find
      if ! command_exists fd && command_exists fdfind; then
        sudo ln -s "$(which fdfind)" /usr/local/bin/fd
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
  local original_dir="$PWD"

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
    cd /tmp || print_error "Failed to change directory to /tmp"

    print_info "Fetching latest Nerd Fonts release..."
    local nerd_fonts_version
    nerd_fonts_version=$(get_latest_github_release "ryanoasis/nerd-fonts")
    if [ -z "$nerd_fonts_version" ]; then
      print_warning "Failed to fetch latest Nerd Fonts version, using fallback v3.1.1"
      nerd_fonts_version="v3.1.1"
    fi

    local font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/${nerd_fonts_version}/UbuntuMono.zip"
    print_info "Downloading Ubuntu Mono Nerd Font ${nerd_fonts_version}..."

    if ! curl -fLo "UbuntuMono.zip" "$font_url"; then
      cd "$original_dir"
      print_error "Failed to download Nerd Font from ${font_url}"
    fi

    unzip -o "UbuntuMono.zip" -d "$font_dir"
    rm "UbuntuMono.zip"

    if [ "$OS" = "linux" ]; then
      fc-cache -fv
    fi

    cd "$original_dir"
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
    local needs_install=false
    if ! command_exists nvim; then
      needs_install=true
    else
      local nvim_version
      nvim_version=$(nvim --version | head -n 1 | grep -oP 'v\K[0-9]+\.[0-9]+' || echo "0.0")
      local major minor
      major=$(echo "$nvim_version" | cut -d. -f1)
      minor=$(echo "$nvim_version" | cut -d. -f2)

      if [ "$major" -lt 1 ] && [ "$minor" -lt 10 ]; then
        needs_install=true
      fi
    fi

    if [ "$needs_install" = true ]; then
      local original_dir="$PWD"
      cd /tmp || print_error "Failed to change directory to /tmp"

      print_info "Fetching latest Neovim release..."
      local nvim_version
      nvim_version=$(get_latest_github_release "neovim/neovim")
      if [ -z "$nvim_version" ]; then
        print_warning "Failed to fetch latest Neovim version, using fallback v0.11.4"
        nvim_version="v0.11.4"
      fi

      local nvim_url="https://github.com/neovim/neovim/releases/download/${nvim_version}/nvim.appimage"
      print_info "Downloading Neovim ${nvim_version}..."

      if ! curl -fLo nvim.appimage "$nvim_url"; then
        cd "$original_dir"
        print_error "Failed to download Neovim AppImage from ${nvim_url}"
      fi

      chmod u+x nvim.appimage
      if [ ! -d "$HOME/.local/bin" ]; then
        mkdir -p "$HOME/.local/bin"
      fi

      if sudo mv nvim.appimage /usr/local/bin/nvim 2>/dev/null; then
        print_success "Neovim AppImage installed to /usr/local/bin/nvim."
      else
        mv nvim.appimage "$HOME/.local/bin/nvim"
        print_success "Neovim AppImage installed to $HOME/.local/bin/nvim."

        if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
          print_warning "Make sure $HOME/.local/bin is in your PATH."
          print_info "Add this to your shell profile: export PATH=\"\$HOME/.local/bin:\$PATH\""
        fi
      fi

      cd "$original_dir"
    else
      print_info "Neovim is already installed with a supported version."
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

  if [ -f "$exe_path" ]; then
    print_info "win32yank already present at $exe_path"
    return 0
  fi

  print_info "Fetching latest win32yank release..."
  local version
  version=$(get_latest_github_release "equalsraf/win32yank")
  if [ -z "$version" ]; then
    print_warning "Failed to fetch latest win32yank version, using fallback v0.1.1"
    version="v0.1.1"
  fi

  local zip_url="https://github.com/equalsraf/win32yank/releases/download/${version}/win32yank-x64.zip"

  mkdir -p "$bin_dir"
  tmp_zip="$(mktemp /tmp/win32yank.XXXXXX.zip)"
  print_info "Downloading win32yank ${version}..."

  if ! curl -fsSL -o "$tmp_zip" "$zip_url"; then
    rm -f "$tmp_zip"
    print_error "Failed to download win32yank ZIP from ${zip_url}"
  fi

  print_info "Extracting win32yank.exe..."
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

  if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    print_warning "Make sure $HOME/.local/bin is in your PATH."
    print_info "Add this to your shell profile: export PATH=\"\$HOME/.local/bin:\$PATH\""
  fi
}

install_clipboard_tools() {
  if [ "$OS" = "macos" ]; then
    print_info "macOS has built-in clipboard tools (pbcopy/pbpaste). Skipping installation."
    return 0
  fi

  print_info "Installing Linux clipboard tools (wl-clipboard/xclip)..."
  check_sudo
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
    print_info "Not running on Linux. Skipping fuse3 installation."
    return 0
  fi

  print_info "Installing fuse3 (for AppImage support)..."
  check_sudo
  if command_exists apt-get; then
    sudo apt-get install -y fuse3
  elif command_exists dnf; then
    sudo dnf install -y fuse3
  elif command_exists pacman; then
    sudo pacman -S --noconfirm fuse3
  else
    print_warning "Could not install fuse3 automatically. Please install it manually if you intend to use AppImages."
  fi
  print_success "Fuse3 installed."
}

install_nvim_packages() {
  print_info "Installing Neovim plugins and Mason packages..."

  print_info "Syncing Lazy plugins..."
  if ! nvim --headless "+Lazy! sync" +qa; then
    print_warning "Lazy plugin sync encountered issues but continuing..."
  fi

  print_info "Updating Mason registry..."
  if ! nvim --headless "+MasonUpdate" +qa; then
    print_warning "Mason update encountered issues but continuing..."
  fi

  print_info "Installing Mason packages (this may take several minutes)..."
  nvim --headless +"lua
    local pkgs = {
      'typescript-language-server',
      'angular-language-server',
      'jdtls',
      'java-debug-adapter',
      'java-test',
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
    local total = #targets
    for _, p in ipairs(targets) do
      p:install():on('closed', function()
        done = done + 1
        print(string.format('Progress: %d/%d packages installed', done, total))
      end)
    end
    local result = vim.wait(300000, function() return done == total end, 1000)
    if not result then
      print('Warning: Mason package installation timed out after 5 minutes.')
      print('Some packages may not be fully installed. You can run :MasonInstall manually.')
    else
      print('Mason package installation complete.')
    end
    " +qa
  print_success "Neovim setup complete."
}

# --- Main Execution ---
main() {
  detect_os
  check_sudo
  print_info "Starting Neovim prerequisites installation for $OS..."

  install_system_packages
  install_node
  install_python
  install_python_packages
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
