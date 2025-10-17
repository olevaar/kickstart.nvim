@echo off
setlocal

:: Neovim Config Prerequisites Installation Script for Windows
::
:: This script installs all the necessary dependencies for the kickstart.nvim configuration on Windows.

set "USER_HOME=%USERPROFILE%"

:: --- Helper Functions ---
:print_info
    echo [INFO] %~1
    goto :EOF

:print_success
    echo [SUCCESS] %~1
    goto :EOF

:print_warning
    echo [WARNING] %~1
    goto :EOF

:print_error
    echo [ERROR] %~1
    exit /b 1

:command_exists
    where %1 >nul 2>nul
    if %errorlevel% equ 0 (
        exit /b 0
    ) else (
        exit /b 1
    )

:: --- Installation Functions ---

:install_winget
    call :print_info "Checking for winget..."
    call :command_exists winget
    if %errorlevel% equ 0 (
        call :print_success "winget is available."
        goto :EOF
    )
    call :print_info "winget not found. Please install it from the Microsoft Store: ms-windows-store://pdp/?ProductId=9NBLGGH4NNS1"
    call :print_error "winget is required to proceed."
    goto :EOF

:install_system_packages
    call :print_info "Installing essential system packages (Git, 7-Zip, Visual Studio Build Tools)..."
    winget install --id Git.Git -e --accept-source-agreements --accept-package-agreements
    winget install --id 7zip.7zip -e --accept-source-agreements --accept-package-agreements
    winget install --id Microsoft.VisualStudio.BuildTools -e --accept-source-agreements --accept-package-agreements --quiet --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended
    call :print_success "Essential system packages installed."
    goto :EOF

:install_fnm_and_node
    call :print_info "Installing fnm and Node.js v22..."
    call :command_exists fnm
    if %errorlevel% neq 0 (
        winget install --id Schniz.fnm -e --accept-source-agreements --accept-package-agreements
        call :print_success "fnm installed."
    ) else (
        call :print_info "fnm is already installed."
    )

    :: The user needs to add fnm to their path manually or restart shell. For now, we assume it's not in the path yet.
    call fnm install 22
    call fnm default 22
    call :print_success "Node.js v22 is set as the default."
    goto :EOF

:install_npm_packages
    call :print_info "Installing global npm packages (markdownlint, @google/gemini-cli)..."
    call npm install -g markdownlint @google/gemini-cli
    call :print_success "Global npm packages installed."
    goto :EOF

:install_java_sdks
    call :print_info "Installing OpenJDK versions..."
    winget install --id Microsoft.OpenJDK.11 -e --accept-source-agreements --accept-package-agreements
    winget install --id Microsoft.OpenJDK.17 -e --accept-source-agreements --accept-package-agreements
    winget install --id Microsoft.OpenJDK.21 -e --accept-source-agreements --accept-package-agreements
    call :print_success "OpenJDK 11, 17, and 21 installed."
    goto :EOF

:install_scoop
    call :print_info "Checking for scoop..."
    call :command_exists scoop
    if %errorlevel% equ 0 (
        call :print_success "scoop is available."
        goto :EOF
    )
    call :print_info "scoop not found, installing..."
    powershell -Command "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser; irm get.scoop.sh | iex"
    call :command_exists scoop
    if %errorlevel% neq 0 (
        call :print_error "Scoop installation failed. Please install it manually."
    )
    call :print_success "scoop installed."
    goto :EOF

:install_kotlin_sdk
    call :print_info "Installing Kotlin SDK via scoop..."
    call :install_scoop
    scoop install kotlin
    call :print_success "Kotlin SDK installed via scoop."
    goto :EOF

:install_kotlin_lsp
    call :print_info "Installing kotlin-lsp..."
    set "KLS_DIR=%USER_HOME%\kotlin-language-server"
    if not exist "%KLS_DIR%" (
        git clone https://github.com/fwcd/kotlin-language-server "%KLS_DIR%"
        cd "%KLS_DIR%"
        call gradlew.bat :server:installDist
        call :print_info "Adding kotlin-language-server to user PATH..."
        setx PATH "%%PATH%%;%KLS_DIR%\server\build\install\server\bin"
        call :print_success "kotlin-lsp installed and added to PATH."
    ) else (
        call :print_info "kotlin-lsp directory already exists. Skipping clone and build."
    )
    cd "%~dp0"
    goto :EOF

:install_ripgrep_fd
    call :print_info "Installing ripgrep and fd..."
    winget install --id BurntSushi.Ripgrep.MSVC -e
    winget install --id sharkdp.fd -e
    call :print_success "ripgrep and fd installed."
    goto :EOF

:install_nerd_font
    call :print_info "Installing Ubuntu Mono Nerd Font..."
    set "FONT_DIR=%LOCALAPPDATA%\Microsoft\Windows\Fonts"
    set "FONT_FILE=%FONT_DIR%\UbuntuMonoNerdFont-Regular.ttf"
    if not exist "%FONT_FILE%" (
        if not exist "%FONT_DIR%" mkdir "%FONT_DIR%"
        set "TMP_ZIP=%TEMP%\UbuntuMono.zip"
        call :print_info "Downloading UbuntuMono.zip..."
        curl -fLo "%TMP_ZIP%" https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/UbuntuMono.zip
        call :print_info "Extracting font files..."
        tar -xf "%TMP_ZIP%" -C "%FONT_DIR%" "*.ttf"
        del "%TMP_ZIP%"
        call :print_success "Ubuntu Mono Nerd Font installed."
        call :print_success "You may now set your terminal font to 'Ubuntu Mono Nerd Font'."
        call :print_success "A system restart might be required for the font to be available everywhere."
    ) else (
        call :print_info "Ubuntu Mono Nerd Font already exists. Skipping installation."
    )
    goto :EOF

:install_neovim
    call :print_info "Installing Neovim (>=0.11.x)..."
    winget install --id Neovim.Neovim -e --accept-source-agreements --accept-package-agreements
    call :print_success "Neovim installed."
    goto :EOF

:install_nvim_packages
    call :print_info "Installing nvim packages via Mason..."
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
    call :print_success "Nvim packages installed."
    goto :EOF

:: --- Main Execution ---
:main
    call :print_info "Starting Neovim prerequisites installation for Windows..."

    call :install_winget
    call :install_system_packages
    call :install_fnm_and_node
    call :install_npm_packages
    call :install_java_sdks
    call :install_kotlin_sdk
    call :install_kotlin_lsp
    call :install_ripgrep_fd
    call :install_nerd_font
    call :install_neovim
    call :install_nvim_packages

    call :print_success "All prerequisites have been installed successfully!"
    call :print_info "Please restart your shell for all changes (especially PATH updates) to take effect."
    goto :EOF

call :main

endlocal
