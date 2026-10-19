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

> Note: You can skip installing all of this manually if you run `install.sh`
> (Linux, WSL, macOS) at the end of this guide. It checks every tool first and
> keeps any existing install that is new enough; only missing or outdated tools
> are installed, via [mise](https://mise.jdx.dev/). Run `./install.sh --dry-run`
> to see what it would do. `install.cmd` (Windows) is untested.

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

For the included LSPs, you need: **Neovim ≥ 0.12**, **node ≥ 22** , **npm**,
**Java JDK ≥ 21**, **Go ≥ 1.22**, and the
[tree-sitter CLI](https://github.com/tree-sitter/tree-sitter) **≥ 0.26.1**
(required by nvim-treesitter's `main` branch).

> Note: `install.sh` uses [mise](https://mise.jdx.dev/) for anything that is
> missing or too old (Neovim, Node.js, Java, Python, Go, Kotlin, ripgrep, fd,
> tree-sitter, lazygit, markdownlint, mdformat, ...). The pinned versions are
> listed at the top of the script. Set `GITHUB_TOKEN` if you hit GitHub API rate
> limits.

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

`install.sh` installs mise automatically if it is missing.

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
   using Mason by typing `:MasonToolsInstall` in Neovim.
   - For Java to work with Lombok, you will need to install the Lombok jar
     manually. Download it from
     [Project Lombok](https://projectlombok.org/download) and place it in the
     JDTLS local directory. Normally this will be located at
     `~/.local/share/nvim/jdtls/`.
   - Kotlin uses JetBrains' official
     [Kotlin LSP](https://github.com/Kotlin/kotlin-lsp) (Alpha; partly
     closed-source, distributed under a JetBrains EULA). It is not installed by
     Mason. `install.sh` installs it via mise, or install it yourself
     (`brew install JetBrains/utils/kotlin-lsp`, or unpack the standalone
     archive) so that `intellij-server` or `kotlin-lsp` is on your `PATH`. It
     starts only inside a Gradle or Maven project, and the install takes about
     1.2 GB on disk.
   - Kotlin debugging uses the same server's built-in debug adapter (no extra
     install). Press `<F5>` to launch a main class, attach to a JVM on port
     5005, or use the `Run`/`Debug` code lens above `main` (`grx`). Maven
     projects need `mvn` on `PATH` for the build before a launch.
1. Run the install.sh script. This installs the plugins at the versions in
   `lazy-lock.json` and the Mason packages. If you skipped the previous steps,
   it also installs any missing dependencies and Neovim itself.

```sh
./install.sh --dry-run   # show what would be installed
./install.sh             # options: --skip-system, --skip-plugins, --extra-jdks
```

#### nvim-redraft and Gemini Configuration

I have also included `nvim-redraft` for fast, inline AI-powered code editing. It is configured to support multiple providers:
- **Gemini 2.5 Flash** (via OpenAI-compatible endpoint)
- **GitHub Copilot** (GPT-4o)

**Keybindings:**
- `<leader>ae` (Visual mode): AI Edit Selection. Select code, press this, and enter an instruction.
- `<leader>am` (Normal mode): Select AI Model. This allows you to switch between Gemini and Copilot.

**Important:** Because `nvim-redraft` is configured to use the OpenAI compatible endpoint for Gemini, you **must** export your Gemini API key as the `OPENAI_API_KEY` environment variable in your shell for the Gemini provider to work:

```sh
export OPENAI_API_KEY="your-gemini-api-key"
```

##### Patching the TypeScript Backend

Because `nvim-redraft` uses the Vercel AI SDK, it currently does not pass the custom `baseURL` correctly to the underlying provider, and the default fallback routing fails when hitting the Gemini endpoint. To fix this, you must apply a patch to the locally installed TypeScript source. If the plugin updates, you may need to re-apply this patch.

Run the following script to patch the file and rebuild the service:

```bash
cat << 'EOF' > patch_redraft.sh
#!/bin/bash
LLM_TS=~/.local/share/nvim/lazy/nvim-redraft/ts/src/llm.ts

if [ -f "$LLM_TS" ]; then
  # 1. Add baseURL to BaseLLMProvider constructor
  sed -i 's/protected maxOutputTokens: number;/protected maxOutputTokens: number;\n  protected baseURL?: string;/g' $LLM_TS
  sed -i 's/constructor(apiKey: string, model: string, maxOutputTokens?: number) {/constructor(apiKey: string, model: string, maxOutputTokens?: number, baseURL?: string) {/g' $LLM_TS
  sed -i 's/this.maxOutputTokens = maxOutputTokens || 4096;/this.maxOutputTokens = maxOutputTokens || 4096;\n    this.baseURL = baseURL;/g' $LLM_TS
  
  # 2. Update OpenAIProvider to use baseURL
  sed -i 's/return createOpenAI({ apiKey: this.apiKey });/return createOpenAI({ apiKey: this.apiKey, baseURL: this.baseURL });/g' $LLM_TS

  # 3. Update PROVIDERS registry mapping to pass baseURL to the constructor
  sed -i 's/new OpenAIProvider(apiKey, model, maxOutputTokens)/new OpenAIProvider(apiKey, model, maxOutputTokens, baseURL)/g' $LLM_TS

  # 4. Force the AI SDK to use the .chat endpoint
  sed -i "s/model: provider(this.model),/model: typeof provider.chat === 'function' ? provider.chat(this.model) : provider(this.model),/g" $LLM_TS

  echo "Patched $LLM_TS"
  cd ~/.local/share/nvim/lazy/nvim-redraft/ts && npm install && npm run build
else
  echo "File not found: $LLM_TS"
fi
EOF
chmod +x patch_redraft.sh && ./patch_redraft.sh
rm patch_redraft.sh
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

