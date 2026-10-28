#!/usr/bin/env bash
#
# Installs Neovim and the external tools this config depends on.
#
# Every tool is checked first: if a working, new-enough version is already on
# PATH (system package, Homebrew, an existing mise install, ...) it is left
# alone. Only missing, broken or too-old tools are installed, and those go
# through mise so that versions are the same on every machine.
#
# Supported: Linux (apt, dnf, pacman, zypper), WSL, macOS.
# Set GITHUB_TOKEN to avoid GitHub API rate limits when mise resolves versions.

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

  -n, --dry-run     Check everything and print what would be installed
      --skip-system Do not install OS packages (git, make, gcc, clipboard, ...)
      --skip-plugins Do not install Neovim plugins and Mason packages
      --extra-jdks  Also install JDK 11 and 17 via mise (not activated globally)
  -h, --help        Show this help
EOF
}

DRY_RUN=0
SKIP_SYSTEM=0
SKIP_PLUGINS=0
EXTRA_JDKS=0

while [ $# -gt 0 ]; do
  case "$1" in
  -n | --dry-run) DRY_RUN=1 ;;
  --skip-system) SKIP_SYSTEM=1 ;;
  --skip-plugins) SKIP_PLUGINS=1 ;;
  --extra-jdks) EXTRA_JDKS=1 ;;
  -h | --help) usage && exit 0 ;;
  *) usage >&2 && exit 2 ;;
  esac
  shift
done

# Tool requirements: minimum acceptable version, and the mise spec used when
# the existing install is missing or insufficient. Bump versions here.
NVIM_MIN=0.12.0 NVIM_MISE="aqua:neovim/neovim@0.12"
NODE_MIN=22.0.0 NODE_MISE="node@22"
PYTHON_MIN=3.9.0 PYTHON_MISE="python@3.12"
GO_MIN=1.22.0 GO_MISE="go@1"
JAVA_MIN=21.0.0 JAVA_MISE="java@temurin-21"
KOTLIN_MIN=1.9.0 KOTLIN_MISE="kotlin@2"
# JetBrains' official Kotlin LSP (bundles its own JRE). Mason's package
# currently points at a dead download host, so it is installed through mise.
KOTLIN_LSP_MIN=263.0.0 KOTLIN_LSP_VERSION=263.7084.0
RG_MIN=13.0.0 RG_MISE="ripgrep@15"
FD_MIN=8.0.0 FD_MISE="fd@10"
TS_MIN=0.26.1 TS_MISE="tree-sitter@0.27"
LAZYGIT_MIN=0.40.0 LAZYGIT_MISE="lazygit@0.66"
MARKDOWNLINT_MISE="npm:markdownlint-cli@0.49"
GEMINI_MISE="npm:@google/gemini-cli@0.65"
MDFORMAT_MISE="pipx:mdformat@1"
UV_MIN=0.5.0 UV_MISE="uv@0.13"
MISE_MIN=2025.6.0

export MISE_YES=1
export DEBIAN_FRONTEND=noninteractive

OS=""
IS_WSL=0
SUMMARY=()
FAILURES=()
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Run mise from $HOME so a project-local mise.toml in the current directory
# cannot influence which versions are detected or installed.
cd "$HOME"

# --- Output -------------------------------------------------------------------

info() { printf '\033[34m[INFO]\033[0m %s\n' "$*"; }
ok() { printf '\033[32m[OK]\033[0m %s\n' "$*"; }
warn() { printf '\033[33m[WARN]\033[0m %s\n' "$*" >&2; }
die() {
  printf '\033[31m[ERROR]\033[0m %s\n' "$*" >&2
  exit 1
}

record() { SUMMARY+=("$(printf '%-24s %s' "$1" "$2")"); }
fail() {
  FAILURES+=("$1")
  record "$1" "FAILED"
}

# --- Helpers ------------------------------------------------------------------

command_exists() { command -v "$1" >/dev/null 2>&1; }

run() {
  if [ "$DRY_RUN" = 1 ]; then
    printf '\033[2m[dry-run]\033[0m %s\n' "$*"
  else
    "$@"
  fi
}

as_root() {
  if [ "$(id -u)" = 0 ]; then
    run "$@"
  elif command_exists sudo; then
    run sudo "$@"
  else
    die "Root privileges required for: $* (sudo not found)"
  fi
}

# Returns 0 if version $1 >= $2. Compares up to three numeric components.
version_ge() {
  local IFS=.
  # shellcheck disable=SC2206
  local -a a=($1) b=($2)
  local i x y
  for i in 0 1 2; do
    x=$((10#${a[i]:-0}))
    y=$((10#${b[i]:-0}))
    [ "$x" -gt "$y" ] && return 0
    [ "$x" -lt "$y" ] && return 1
  done
  return 0
}

# Runs a version command and prints the first x.y[.z] found in its output.
# Fails if the command itself fails (broken install, unset mise shim, ...).
tool_version() {
  local out
  out=$("$@" 2>&1) || return 1
  printf '%s\n' "$out" | grep -Eo '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1
}

refresh_mise_env() {
  command_exists mise || return 0
  eval "$(mise env -s bash)"
}

mise_use() {
  if ! run mise use -g "$1"; then
    return 1
  fi
  [ "$DRY_RUN" = 1 ] || refresh_mise_env
}

# check_tool LABEL MIN CMD [ARGS...]
# MIN may be empty (only require the command to exist) or 0 (any version, but
# the command must run successfully).
check_tool() {
  local label=$1 min=$2 cmd=$3 path ver
  shift 2
  path=$(command -v "$cmd" 2>/dev/null) || return 1
  if [ -z "$min" ]; then
    ok "$label found at $path"
    record "$label" "existing ($path)"
    return 0
  fi
  if ! ver=$(tool_version "$@"); then
    if [ "$min" = 0 ] && "$@" >/dev/null 2>&1; then
      ok "$label found at $path"
      record "$label" "existing ($path)"
      return 0
    fi
    warn "$label at $path does not run ('$*' failed); it is broken or an unset mise shim"
    return 1
  fi
  if version_ge "$ver" "$min"; then
    ok "$label $ver found at $path"
    record "$label" "existing $ver ($path)"
    return 0
  fi
  warn "$label $ver at $path is older than required $min"
  return 1
}

# install_tool LABEL MIN MISE_SPEC CMD [ARGS...]
install_tool() {
  local label=$1 min=$2 spec=$3 ver
  shift 3
  # Display form without backend options: "http:x[url=...]@1" -> "http:x@1".
  local name="$spec"
  case "$spec" in *\[*) name="${spec%%\[*}@${spec##*@}" ;; esac
  info "Installing $label via mise ($name)..."
  if ! mise_use "$spec"; then
    warn "mise failed to install $spec"
    fail "$label"
    return 0
  fi
  if [ "$DRY_RUN" = 1 ]; then
    record "$label" "would install via mise ($name)"
    return 0
  fi
  if [ -z "$min" ] || [ "$min" = 0 ]; then
    if command_exists "$1"; then
      record "$label" "installed via mise ($name)"
      return 0
    fi
  elif ver=$(tool_version "$@") && version_ge "$ver" "$min"; then
    record "$label" "installed $ver via mise ($name)"
    return 0
  fi
  warn "$label was installed by mise but '$1' is still not usable on PATH"
  fail "$label"
}

# ensure_tool LABEL MIN MISE_SPEC CMD [ARGS...]
ensure_tool() {
  local label=$1 min=$2 spec=$3
  shift 3
  check_tool "$label" "$min" "$@" || install_tool "$label" "$min" "$spec" "$@"
}

# --- Platform -----------------------------------------------------------------

detect_os() {
  case "$(uname -s)" in
  Linux*)
    OS=linux
    if grep -qi microsoft /proc/version 2>/dev/null; then IS_WSL=1; fi
    ;;
  Darwin*) OS=macos ;;
  *) die "Unsupported operating system: $(uname -s)" ;;
  esac
  info "Platform: $OS$([ "$IS_WSL" = 1 ] && echo ' (WSL)') $(uname -m)"
}

package_manager() {
  local pm
  for pm in apt-get dnf pacman zypper; do
    if command_exists "$pm"; then
      echo "$pm"
      return 0
    fi
  done
  return 1
}

# Maps a required command to the package that provides it.
package_for() {
  local pm=$1 cmd=$2
  case "$cmd" in
  make | gcc) [ "$pm" = apt-get ] && echo build-essential || echo "$cmd" ;;
  fc-cache) echo fontconfig ;;
  wl-copy) echo wl-clipboard ;;
  *) echo "$cmd" ;;
  esac
}

install_system_packages() {
  if [ "$SKIP_SYSTEM" = 1 ]; then
    info "Skipping OS packages (--skip-system)."
    return 0
  fi

  if [ "$OS" = macos ]; then
    if ! xcode-select -p >/dev/null 2>&1; then
      run xcode-select --install || true
      die "Xcode Command Line Tools are required (git, make, clang). Finish their installation, then re-run this script."
    fi
    ok "Xcode Command Line Tools present"
    return 0
  fi

  local -a needed=(git curl unzip tar make gcc)
  [ "$IS_WSL" = 1 ] || needed+=(fc-cache)

  if [ "$IS_WSL" = 0 ] && ! command_exists wl-copy && ! command_exists xclip && ! command_exists xsel; then
    if [ -n "${WAYLAND_DISPLAY:-}" ]; then
      needed+=(wl-copy)
    elif [ -n "${DISPLAY:-}" ]; then
      needed+=(xclip)
    else
      info "No graphical session detected; skipping clipboard tool."
    fi
  fi

  local -a missing=() packages=()
  local cmd pkg
  for cmd in "${needed[@]}"; do
    command_exists "$cmd" && continue
    missing+=("$cmd")
  done

  if [ ${#missing[@]} -eq 0 ]; then
    ok "OS packages present (${needed[*]})"
    return 0
  fi

  local pm
  pm=$(package_manager) || die "No supported package manager found. Install these manually: ${missing[*]}"

  for cmd in "${missing[@]}"; do
    pkg=$(package_for "$pm" "$cmd")
    case " ${packages[*]-} " in *" $pkg "*) ;; *) packages+=("$pkg") ;; esac
  done

  info "Installing OS packages via $pm: ${packages[*]}"
  case "$pm" in
  apt-get)
    as_root apt-get update
    as_root apt-get install -y "${packages[@]}"
    ;;
  dnf) as_root dnf install -y "${packages[@]}" ;;
  pacman)
    as_root pacman -S --needed --noconfirm "${packages[@]}" ||
      die "pacman failed. If packages were not found, update the system first (sudo pacman -Syu) and re-run."
    ;;
  zypper) as_root zypper --non-interactive install "${packages[@]}" ;;
  esac
  record "OS packages" "installed ${packages[*]}"
}

# --- mise ---------------------------------------------------------------------

install_mise() {
  if command_exists mise; then
    local ver
    ver=$(tool_version mise --version) || die "mise at $(command -v mise) does not run."
    if ! version_ge "$ver" "$MISE_MIN"; then
      warn "mise $ver is older than $MISE_MIN; the aqua/github/npm/pipx backends may be missing. Upgrade mise if installs fail."
    fi
    ok "mise $ver found at $(command -v mise)"
    record "mise" "existing $ver"
  else
    info "Installing mise..."
    if command_exists pacman; then
      as_root pacman -S --needed --noconfirm mise
    elif [ "$OS" = macos ] && command_exists brew; then
      run brew install mise
    else
      run sh -c 'curl -fsSL https://mise.run | sh'
      export PATH="$HOME/.local/bin:$PATH"
    fi
    if [ "$DRY_RUN" = 0 ] && ! command_exists mise; then
      die "mise installation failed. See https://mise.jdx.dev/getting-started.html"
    fi
    record "mise" "$([ "$DRY_RUN" = 1 ] && echo 'would install' || echo 'installed')"
  fi

  setup_mise_activation
  refresh_mise_env
}

setup_mise_activation() {
  if [ -n "${MISE_SHELL:-}" ]; then
    return 0
  fi

  local shell_name rc line mise_bin
  shell_name=$(basename "${SHELL:-bash}")
  mise_bin=$(command -v mise 2>/dev/null || echo "$HOME/.local/bin/mise")
  case "$shell_name" in
  bash)
    rc="$HOME/.bashrc"
    line="eval \"\$($mise_bin activate bash)\""
    ;;
  zsh)
    rc="$HOME/.zshrc"
    line="eval \"\$($mise_bin activate zsh)\""
    ;;
  fish)
    rc="$HOME/.config/fish/config.fish"
    line="$mise_bin activate fish | source"
    ;;
  *)
    warn "Unknown shell '$shell_name'. Activate mise manually: https://mise.jdx.dev/getting-started.html"
    return 0
    ;;
  esac

  if [ -f "$rc" ] && grep -q "mise activate" "$rc"; then
    return 0
  fi
  info "Adding mise activation to $rc"
  if [ "$DRY_RUN" = 1 ]; then
    run "echo '$line' >> $rc"
  else
    mkdir -p "$(dirname "$rc")"
    printf '\n# mise (tool version manager)\n%s\n' "$line" >>"$rc"
  fi
}

# --- Tools --------------------------------------------------------------------

# Prints the mise spec for JetBrains' Kotlin LSP archive on this platform.
kotlin_lsp_spec() {
  local v=$KOTLIN_LSP_VERSION suffix="" ext=tar.gz url
  case "$OS-$(uname -m)" in
  linux-x86_64) ;;
  linux-aarch64 | linux-arm64) suffix=-aarch64 ;;
  macos-x86_64) ext=sit ;;
  macos-arm64) suffix=-aarch64 ext=sit ;;
  *) return 1 ;;
  esac
  url="https://download.jetbrains.com/language-server/kotlin-server/$v/kotlin-server-$v$suffix.$ext"
  # The macOS .sit archives are zip files.
  if [ "$ext" = sit ]; then
    echo "http:kotlin-lsp[url=$url,checksum_url=$url.sha256,format=zip]@$v"
  else
    echo "http:kotlin-lsp[url=$url,checksum_url=$url.sha256]@$v"
  fi
}

install_tools() {
  ensure_tool "Neovim" "$NVIM_MIN" "$NVIM_MISE" nvim --version

  ensure_tool "Node.js" "$NODE_MIN" "$NODE_MISE" node --version
  if [ "$DRY_RUN" = 0 ] || command_exists node; then
    if ! check_tool "npm" 0 npm --version; then
      install_tool "Node.js (for npm)" "$NODE_MIN" "$NODE_MISE" node --version
    fi
  fi

  ensure_tool "Python" "$PYTHON_MIN" "$PYTHON_MISE" python3 --version
  ensure_tool "Go" "$GO_MIN" "$GO_MISE" go version
  ensure_tool "Java" "$JAVA_MIN" "$JAVA_MISE" java -version
  ensure_tool "Kotlin" "$KOTLIN_MIN" "$KOTLIN_MISE" kotlinc -version
  local kotlin_lsp kotlin_lsp_cmd=intellij-server
  if ! command_exists intellij-server && command_exists kotlin-lsp; then kotlin_lsp_cmd=kotlin-lsp; fi
  if kotlin_lsp=$(kotlin_lsp_spec); then
    ensure_tool "Kotlin LSP" "$KOTLIN_LSP_MIN" "$kotlin_lsp" "$kotlin_lsp_cmd" --version
  else
    warn "Kotlin LSP has no build for $OS $(uname -m); skipping."
    record "Kotlin LSP" "skipped (unsupported platform)"
  fi

  ensure_tool "ripgrep" "$RG_MIN" "$RG_MISE" rg --version
  local fd_cmd=fd
  if ! command_exists fd && command_exists fdfind; then fd_cmd=fdfind; fi
  ensure_tool "fd" "$FD_MIN" "$FD_MISE" "$fd_cmd" --version
  ensure_tool "tree-sitter CLI" "$TS_MIN" "$TS_MISE" tree-sitter --version
  ensure_tool "lazygit" "$LAZYGIT_MIN" "$LAZYGIT_MISE" lazygit --version

  ensure_tool "markdownlint" 0 "$MARKDOWNLINT_MISE" markdownlint --version
  ensure_tool "gemini CLI" 0 "$GEMINI_MISE" gemini --version

  if ! check_tool "mdformat" 0 mdformat --version; then
    # mise installs Python tools with uv when it is available, else pipx. Old
    # distro pipx (e.g. 1.4.3 on Ubuntu 24.04) makes mise print a spurious
    # "pipx failed" error, so always provide uv.
    ensure_tool "uv" "$UV_MIN" "$UV_MISE" uv --version
    install_tool "mdformat" 0 "$MDFORMAT_MISE" mdformat --version
  fi

  if [ "$EXTRA_JDKS" = 1 ]; then
    local v
    for v in 11 17; do
      info "Installing JDK $v via mise (not activated globally)..."
      if run mise install "java@temurin-$v"; then
        record "JDK $v" "installed via mise (mise where java@temurin-$v)"
      else
        fail "JDK $v"
      fi
    done
  fi
}

# --- Extras -------------------------------------------------------------------

install_nerd_font() {
  local font_dir file
  if [ "$IS_WSL" = 1 ]; then
    info "WSL: install a Nerd Font on Windows and select it in your terminal: https://www.nerdfonts.com/font-downloads"
    return 0
  fi
  case "$OS" in
  linux) font_dir="$HOME/.local/share/fonts" ;;
  macos) font_dir="$HOME/Library/Fonts" ;;
  esac
  file="$font_dir/UbuntuMonoNerdFont-Regular.ttf"

  if [ -f "$file" ] || { command_exists fc-list && fc-list 2>/dev/null | grep -qi "UbuntuMono Nerd"; }; then
    ok "UbuntuMono Nerd Font present"
    record "Nerd Font" "existing"
    return 0
  fi

  info "Installing UbuntuMono Nerd Font..."
  local zip="$TMP_DIR/UbuntuMono.zip"
  if run curl -fsSL -o "$zip" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/UbuntuMono.zip" &&
    run mkdir -p "$font_dir" &&
    run unzip -o -q "$zip" '*.ttf' -d "$font_dir"; then
    if [ "$OS" = linux ] && command_exists fc-cache; then run fc-cache -f "$font_dir"; fi
    if [ "$DRY_RUN" = 1 ]; then
      record "Nerd Font" "would install"
    else
      record "Nerd Font" "installed (set your terminal font to 'UbuntuMono Nerd Font')"
    fi
  else
    fail "Nerd Font"
  fi
}

install_win32yank() {
  [ "$IS_WSL" = 1 ] || return 0
  if check_tool "win32yank" "" win32yank.exe; then
    return 0
  fi

  info "Installing win32yank (WSL clipboard)..."
  local zip="$TMP_DIR/win32yank.zip" bin="$HOME/.local/bin"
  if run curl -fsSL -o "$zip" "https://github.com/equalsraf/win32yank/releases/latest/download/win32yank-x64.zip" &&
    run mkdir -p "$bin" &&
    run unzip -o -q "$zip" win32yank.exe -d "$bin" &&
    run chmod +x "$bin/win32yank.exe"; then
    record "win32yank" "installed ($bin/win32yank.exe)"
    case ":$PATH:" in *":$bin:"*) ;; *) warn "Add $bin to your PATH." ;; esac
  else
    fail "win32yank"
  fi
}

# Runs a Lua expression in headless Neovim and fails if it raises an error.
nvim_lua() {
  run nvim --headless -c "lua local ok, err = pcall(function() $1 end); if not ok then io.stderr:write(tostring(err) .. '\n'); vim.cmd('cquit 1') end" -c qa
}

install_nvim_plugins() {
  if [ "$SKIP_PLUGINS" = 1 ]; then
    info "Skipping plugins (--skip-plugins)."
    return 0
  fi
  if [ "$DRY_RUN" = 0 ] && ! command_exists nvim; then
    fail "Neovim plugins"
    return 0
  fi

  info "Installing plugins at the versions in lazy-lock.json..."
  if ! run nvim --headless "+Lazy! restore" +qa || ! nvim_lua "require('configs.bootstrap').verify_plugins()"; then
    fail "Lazy plugins"
    return 0
  fi
  record "Lazy plugins" "$([ "$DRY_RUN" = 1 ] && echo 'would restore' || echo 'restored') from lazy-lock.json"

  info "Installing treesitter parsers..."
  if nvim_lua "require('configs.treesitter').install_sync()"; then
    record "Treesitter parsers" "$([ "$DRY_RUN" = 1 ] && echo 'would install' || echo 'installed')"
  else
    fail "Treesitter parsers"
  fi

  info "Installing Mason packages (this may take several minutes)..."
  if nvim_lua "require('configs.bootstrap').install_mason_sync()"; then
    record "Mason packages" "$([ "$DRY_RUN" = 1 ] && echo 'would install' || echo 'installed')"
  else
    fail "Mason packages"
  fi
}

# --- Main ---------------------------------------------------------------------

print_summary() {
  echo
  info "Summary:"
  local line
  for line in ${SUMMARY[@]+"${SUMMARY[@]}"}; do
    printf '  %s\n' "$line"
  done
  echo
  if [ ${#FAILURES[@]} -gt 0 ]; then
    warn "Failed: ${FAILURES[*]}"
    return 1
  fi
  if [ "$DRY_RUN" = 1 ]; then
    info "Dry run complete; nothing was changed."
  else
    ok "Done. Restart your shell so mise-managed tools are on PATH."
  fi
}

main() {
  [ "$DRY_RUN" = 1 ] && info "Dry run: nothing will be changed."
  detect_os
  install_system_packages
  install_mise
  install_tools
  install_nerd_font
  install_win32yank
  install_nvim_plugins
  print_summary
}

main
