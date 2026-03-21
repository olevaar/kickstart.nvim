# olevaar nvim config (kickstart.nvim fork)

## Introduction

This is my Neovim configuration. There are many like it, but this one is mine.
It is built on top of
[kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) which is a minimal
Neovim configuration for kickstarting your own setup.

## Installation

### Install Neovim

Grab the latest version of Neovim from the
[Neovim Releases Page](https://github.com/neovim/neovim/releases).

### Install External Dependencies

> Note: You can skip installing all of this manually if you run the `install.sh`
> or `install.cmd` (for Windows) script at the end of this guide. It will
> install everything you need. However, I have only actually tested this on
> Ubuntu and Debian. I had Gemini duplicate it for other distros, as well as
> Windows and MacOS, but those installs are untested.

External Requirements:

- Basic utils: `git`, `make`, `unzip`, C Compiler (`gcc`)
- [ripgrep](https://github.com/BurntSushi/ripgrep#installation), (optional, but
  highly recommended)
- [fd-find](https://github.com/sharkdp/fd#installation) (optional, but highly
  recommended)
- Clipboard tool (xclip/xsel/win32yank or other depending on the platform)
- A [Nerd Font](https://www.nerdfonts.com/): optional, provides various icons
  - if you have it set `vim.g.have_nerd_font` in `init.lua` to true
- Emoji fonts (Ubuntu only, and only if you want emoji!)
  `sudo apt install fonts-noto-color-emoji`
- Language Setup:
  - If you want to write Typescript, you need `npm`
  - If you want to write Golang, you will need `go`
  - etc.

For the included LSPs, you need: **node ≥ 22** , **npm**, **Java JDK ≥ 21**, **Go ≥ 1.22**

> Note: If [mise](https://mise.jdx.dev/) is available on your system, it will be
> used automatically to manage Node.js, Java, Python, and Go installations instead
> of fnm or direct system installs. This provides better version management
> across projects.

#### Ubuntu / Debian (apt)

```sh
sudo apt update
sudo apt install -y git curl ripgrep fd-find
```

<!-- markdownlint-disable-next-line MD028 -->

> Note: Java and Python will be managed by mise if available, otherwise you can
> install them manually with `sudo apt install -y openjdk-21-jdk python3`

<!-- markdownlint-disable-next-line MD028 -->

> Note: on Debian/Ubuntu the `fd` binary is named `fdfind`. You can symlink it
> if you like:

```sh
sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd
```

#### Fedora / RHEL (dnf)

```sh
sudo dnf install -y git curl ripgrep fd-find
```

> Note: Java and Python will be managed by mise if available, otherwise you can
> install them manually with `sudo dnf install -y java-21-openjdk-devel python3`
> Fedora’s `fd` binary may be `fdfind`. Symlink if desired:

```sh
sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd
```

#### Arch / Manjaro (pacman)

```sh
sudo pacman -Syu --needed git curl ripgrep fd
```

> Arch’s `jdk-openjdk` installs the current LTS. If you specifically need 17,
> use your preferred method (AUR or sdkman).

#### macOS (Homebrew)

```sh
brew update
brew install git curl ripgrep fd
```

> Note: Java and Python will be managed by mise if available, otherwise you can
> install them manually with `brew install temurin python3`

______________________________________________________________________

### Install Runtime Versions (Node.js, Java, Python)

This configuration uses [mise](https://mise.jdx.dev/) when available to manage
Node.js, Java, and Python versions. Mise will automatically be used if it's
installed on your system.

#### Install mise (recommended)

```sh
curl https://mise.run | sh
```

Or with Homebrew (macOS):

```sh
brew install mise
```

If mise is not available, the configuration will fall back to using `fnm` for
Node.js and system-installed Java and Python.

<!-- markdownlint-disable MD033 -->

<details><summary>Alternative: Install Node.js with fnm (if not using mise)</summary>

#### Install `fnm`

- Curl installer:

```sh
curl -fsSL https://fnm.vercel.app/install | bash
```

- Or Homebrew (macOS):

```sh
brew install fnm
```

</details>

### Install this configuration

Neovim's configurations are located under the following paths, depending on your
OS:

| OS | PATH | | :------------------- | :----------------------------------------
| | Linux, MacOS | `$XDG_CONFIG_HOME/nvim`, `~/.config/nvim` | | Windows (cmd) |
`%localappdata%\nvim\` | | Windows (powershell) | `$env:LOCALAPPDATA\nvim\` |

#### Clone nvim-config

<!-- markdownlint-disable MD033 -->

<details><summary> Linux and Mac </summary>

```sh
git clone https://github.com/olevaar/kickstart.nvim.git "${XDG_CONFIG_HOME:-$HOME/.config}"/nvim
```

</details>

<details><summary> Windows </summary>

If you're using `cmd.exe`:

```sh
git clone https://github.com/olevaar/kickstart.nvim.git "%localappdata%\nvim"
```

If you're using `powershell.exe`

```sh
git clone https://github.com/olevaar/kickstart.nvim.git "${env:LOCALAPPDATA}\nvim"
```

</details>
<!-- markdownlint-enable MD033 -->

### Post Installation

You now have two options to install the plugins and LSP servers.

1. Open Neovim and Lazy will automatically install the plugins for you. You can
   do this by running `nvim` in your terminal. You can also install the LSPs
   using Mason by typing `:MasonInstallAll` in Neovim.
   - For Java to work with Lombok, you will need to install the Lombok jar
     manually. Download it from
     [Project Lombok](https://projectlombok.org/download) and place it in the
     JDTLS local directory. Normally this will be located at
     `~/.local/share/nvim/jdtls/`.
1. Run the install.sh script. This will install all the plugins and set up the
   LSP servers. If you skipped all the previous steps, this script will also
   install any dependencies and neovim itself.

```sh
chmod +x install.sh
./install.sh
```

#### sidekick.nvim and Github Copilot configuration

> Note: I have decided to disable avante.nvim and magenta.nvim by default.
> Instead, I included [sidekick.nvim](https://github.com/folke/sidekick.nvim) as
> the primary AI assistant. Sidekick provides a powerful CLI interface for AI
> interactions and integrates seamlessly with your codebase.

Github Copilot requires you to be signed in to your Github account. You can do
this by running `:Copilot auth` in Neovim. Once you are signed in, you can start
using Copilot as the backend for your AI tasks.

Sidekick.nvim is configured with several helpful keybindings:

- `<tab>`: Jump to or apply the next edit suggestion.
- `<leader>aa`: Toggle the Sidekick CLI.
- `<leader>as`: Select a CLI tool.
- `<leader>ad`: Detach a CLI session.
- `<leader>at`: Send "this" (contextual element) to the CLI.
- `<leader>af`: Send the entire current file to the CLI.
- `<leader>av`: Send the current visual selection to the CLI.
- `<leader>ap`: Open the Sidekick prompt selector.

See the documentation for sidekick.nvim at:
[https://github.com/folke/sidekick.nvim](https://github.com/folke/sidekick.nvim)

