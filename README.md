# olevaar nvim config (kickstart.nvim fork)

## Introduction

This is my Neovim configuration.
There are many like it, but this one is mine.
It is built on top of
[kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim)
which is a minimal Neovim configuration for kickstarting your own setup.

## Installation

### Install Neovim

Grab the latest version of Neovim from the
[Neovim Releases Page](https://github.com/neovim/neovim/releases).

### Install External Dependencies

> Note: You can skip installing all of this manually if you run the `install.sh`
or `install.cmd` (for Windows) script at the end of this guide. It will install
everything you need. However, I have only actually tested this on Ubuntu and
Debian. I had Gemini duplicate it for other distros, as well as Windows and
MacOS, but those installs are untested.

External Requirements:

- Basic utils: `git`, `make`, `unzip`, C Compiler (`gcc`)
- [ripgrep](https://github.com/BurntSushi/ripgrep#installation),
(optional, but highly recommended)
- [fd-find](https://github.com/sharkdp/fd#installation) (optional, but highly recommended)
- Clipboard tool (xclip/xsel/win32yank or other depending on the platform)
- A [Nerd Font](https://www.nerdfonts.com/): optional, provides various icons
  - if you have it set `vim.g.have_nerd_font` in `init.lua` to true
- Emoji fonts (Ubuntu only, and only if you want emoji!)
`sudo apt install fonts-noto-color-emoji`
- Language Setup:
  - If you want to write Typescript, you need `npm`
  - If you want to write Golang, you will need `go`
  - etc.

For the included LSPs, you need: **node ≥ 22** , **npm**, **Java JDK ≥ 21**

#### Ubuntu / Debian (apt)

```sh
sudo apt update
sudo apt install -y git curl ripgrep fd-find
sudo apt install -y openjdk-17-jdk
```

> Note: on Debian/Ubuntu the `fd` binary is named `fdfind`. You can symlink it
if you like:

```sh
sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd
```

#### Fedora / RHEL (dnf)

```sh
sudo dnf install -y git curl ripgrep fd-find java-17-openjdk-devel
```

> Fedora’s `fd` binary may be `fdfind`. Symlink if desired:

```sh
sudo ln -sf "$(command -v fdfind)" /usr/local/bin/fd
```

#### Arch / Manjaro (pacman)

```sh
sudo pacman -Syu --needed git curl ripgrep fd jdk-openjdk
```

> Arch’s `jdk-openjdk` installs the current LTS. If you specifically need 17,
use your preferred method (AUR or sdkman).

#### macOS (Homebrew)

```sh
brew update
brew install git curl ripgrep fd temurin
```

> Temurin provides an OpenJDK build. Alternatively use `brew install openjdk`.

---

### Install Node.js with `fnm` (Node ≥ 22)

#### Install `fnm`

- Curl installer:

```sh
curl -fsSL https://fnm.vercel.app/install | bash
```

- Or Homebrew (macOS):

```sh
brew install fnm
```

### Install this configuration

Neovim's configurations are located under the following paths, depending on
your OS:

| OS | PATH |
| :- | :--- |
| Linux, MacOS | `$XDG_CONFIG_HOME/nvim`, `~/.config/nvim` |
| Windows (cmd)| `%localappdata%\nvim\` |
| Windows (powershell)| `$env:LOCALAPPDATA\nvim\` |

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

1. Open Neovim and Lazy will automatically install the plugins for you.
   You can do this by running `nvim` in your terminal. You can also install the
LSPs using Mason by typing `:MasonInstallAll` in Neovim.
   - For Java to work with Lombok, you will need to install the Lombok jar
   manually. Download it from
   [Project Lombok](https://projectlombok.org/download) and place it in the
   JDTLS local directory. Normally this will be located at
   `~/.local/share/nvim/jdtls/`.
2. Run the install.sh script. This will install all the plugins and set up the
LSP servers.

```sh
chmod +x install.sh 
./install.sh
```

#### Avante.nvim and Github Copilot configuration

> Note: I have decided to disable avante.nvim by default. Instead, I included
magenta.nvim as the default AI assistant. If you want to use avante.nvim,
you will need to enable it in the `lua/plugins/avante.lua` file by setting
`enabled = true`. I found the copilot integration with avante.nvim to be a bit
buggy, so I decided to disable it for now. In addition, there was some
controversy about avante.nvim copying code from copilot without attribution a
wile back.

In this config Avante.nvim is setup to work with Github Copilot and Google
Gemini. You can change these providers if you want (to for example Anthropic
or OpenAI), or disable these plugins entirely.

Google Gemini requires an API key to work. You can get one from the
[Google AI Studio](https://developers.generativeai.google). Once you have the
key, you can set it in your environment variables as `GOOGLE_API_KEY`.

Github Copilot requires you to be signed in to your Github account. You can do
this by running `:Copilot auth` in Neovim. This will open a browser window
where you can sign in to your account. Once you are signed in, you can start
using Copilot.

The default keybinding for using Avante.nvim is ```<leader>an``` for a new chat
and ```<leader>aa``` to open the last chat. You can change these keybindings in
the `lua/plugins/avante.lua` file. ```<leader>ap``` is used to toggle between
providers.
