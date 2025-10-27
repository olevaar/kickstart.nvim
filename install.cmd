@echo off
setlocal

:: Neovim Config Prerequisites Installation Script for Windows
::
:: This script installs all the necessary dependencies for the kickstart.nvim configuration on Windows.
:: 
:: This script was implemented by Gemini, and is currently untested. 

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

:get_latest_github_release
    for /f "delims=" %%i in ('powershell -Command "(Invoke-RestMethod -Uri 'https://api.github.com/repos/%~1/releases/latest').tag_name"') do set "LATEST_VERSION=%%i"
    exit /b 0

:check_admin
    net session >nul 2>&1
    if %errorlevel% neq 0 (
        call :print_warning "Some operations may require administrator privileges."
        call :print_info "Consider running this script as Administrator if you encounter permission errors."
    )
    exit /b 0

:: --- Installation Functions ---

:install_winget
    call :print_info "Checking for winget..."
    call :command_exists winget
    if %errorlevel% equ 0 (
        call :print_success "winget is available."
        exit /b 0
    )
    call :print_error "winget not found. Please install it from the Microsoft Store: ms-windows-store://pdp/?ProductId=9NBLGGH4NNS1"
    exit /b 1

:install_system_packages
    call :print_info "Installing essential system packages (Git, 7-Zip, Python, Visual Studio Build Tools)..."
    winget install --id Git.Git -e --accept-source-agreements --accept-package-agreements
    if %errorlevel% neq 0 (
        call :print_warning "Git installation failed or was skipped."
    )
    
    winget install --id 7zip.7zip -e --accept-source-agreements --accept-package-agreements
    if %errorlevel% neq 0 (
        call :print_warning "7-Zip installation failed or was skipped."
    )
    
    call :print_info "Installing Python..."
    winget install --id Python.Python.3.12 -e --accept-source-agreements --accept-package-agreements
    if %errorlevel% neq 0 (
        call :print_warning "Python installation failed or was skipped."
    )
    
    call :print_info "Installing Visual Studio Build Tools (this may take a while)..."
    winget install --id Microsoft.VisualStudio.2022.BuildTools -e --accept-source-agreements --accept-package-agreements --override "--quiet --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
    if %errorlevel% neq 0 (
        call :print_warning "Visual Studio Build Tools installation failed or was skipped."
    )
    
    call :print_success "Essential system packages installation completed."
    exit /b 0

:install_fnm_and_node
    call :print_info "Installing fnm and Node.js v22..."
    call :command_exists fnm
    if %errorlevel% neq 0 (
        winget install --id Schniz.fnm -e --accept-source-agreements --accept-package-agreements
        if %errorlevel% neq 0 (
            call :print_error "Failed to install fnm."
            exit /b 1
        )
        call :print_success "fnm installed."
        
        :: Add fnm to current session PATH
        set "PATH=%LOCALAPPDATA%\fnm;%PATH%"
        
        :: Check if fnm is now accessible
        call :command_exists fnm
        if %errorlevel% neq 0 (
            call :print_warning "fnm was installed but is not yet in PATH. Please restart your shell and run: fnm install 22 && fnm default 22"
            exit /b 0
        )
    ) else (
        call :print_info "fnm is already installed."
    )

    call :print_info "Installing Node.js v22..."
    call fnm install 22
    if %errorlevel% neq 0 (
        call :print_warning "Failed to install Node.js v22. You may need to run 'fnm install 22' manually after restarting your shell."
        exit /b 0
    )
    
    call fnm default 22
    if %errorlevel% neq 0 (
        call :print_warning "Failed to set Node.js v22 as default."
    )
    
    call :print_success "Node.js v22 setup completed."
    exit /b 0

:install_python_packages
    call :print_info "Installing Python packages via pipx (mdformat)..."
    
    :: Check if python is available
    call :command_exists python
    if %errorlevel% neq 0 (
        call :print_warning "Python is not available in PATH. This is expected if Python was just installed."
        call :print_info "Please restart your shell and run: python -m pip install --user pipx && python -m pipx ensurepath && pipx install mdformat"
        exit /b 0
    )
    
    :: Install pipx if not already installed
    call :command_exists pipx
    if %errorlevel% neq 0 (
        call :print_info "Installing pipx..."
        python -m pip install --user pipx
        if %errorlevel% neq 0 (
            call :print_warning "Failed to install pipx. You may need to restart your shell and try again."
            exit /b 0
        )
        
        python -m pipx ensurepath
        if %errorlevel% neq 0 (
            call :print_warning "Failed to configure pipx PATH."
        )
        
        :: Add pipx to current session PATH
        set "PATH=%USERPROFILE%\AppData\Roaming\Python\Python312\Scripts;%PATH%"
    ) else (
        call :print_info "pipx is already installed."
    )
    
    :: Install mdformat
    call :command_exists pipx
    if %errorlevel% neq 0 (
        call :print_warning "pipx is not available in PATH. Please restart your shell and run: pipx install mdformat"
        exit /b 0
    )
    
    pipx install mdformat
    if %errorlevel% neq 0 (
        call :print_warning "Failed to install mdformat via pipx."
        exit /b 0
    )
    
    call :print_success "Python packages installed."
    exit /b 0

:install_npm_packages
    call :print_info "Installing global npm packages (markdownlint, @google/gemini-cli)..."
    
    :: Check if npm is available
    call :command_exists npm
    if %errorlevel% neq 0 (
        call :print_warning "npm is not available in PATH. This is expected if Node.js was just installed."
        call :print_info "Please restart your shell and run: npm install -g markdownlint-cli @google/gemini-cli"
        exit /b 0
    )
    
    call npm install -g markdownlint-cli @google/gemini-cli
    if %errorlevel% neq 0 (
        call :print_warning "Failed to install npm packages. You may need to restart your shell and try again."
        exit /b 0
    )
    
    call :print_success "Global npm packages installed."
    exit /b 0

:install_java_sdks
    call :print_info "Installing OpenJDK versions..."
    winget install --id Microsoft.OpenJDK.11 -e --accept-source-agreements --accept-package-agreements
    if %errorlevel% neq 0 (
        call :print_warning "OpenJDK 11 installation failed or was skipped."
    )
    
    winget install --id Microsoft.OpenJDK.17 -e --accept-source-agreements --accept-package-agreements
    if %errorlevel% neq 0 (
        call :print_warning "OpenJDK 17 installation failed or was skipped."
    )
    
    winget install --id Microsoft.OpenJDK.21 -e --accept-source-agreements --accept-package-agreements
    if %errorlevel% neq 0 (
        call :print_warning "OpenJDK 21 installation failed or was skipped."
    )
    
    call :print_success "OpenJDK installation process completed."
    exit /b 0

:install_scoop
    call :print_info "Checking for scoop..."
    call :command_exists scoop
    if %errorlevel% equ 0 (
        call :print_success "scoop is available."
        exit /b 0
    )
    
    call :print_info "scoop not found, installing..."
    powershell -Command "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force; irm get.scoop.sh | iex"
    if %errorlevel% neq 0 (
        call :print_error "Scoop installation failed. Please install it manually from https://scoop.sh"
        exit /b 1
    )
    
    :: Add scoop to current session PATH
    set "PATH=%USERPROFILE%\scoop\shims;%PATH%"
    
    call :command_exists scoop
    if %errorlevel% neq 0 (
        call :print_warning "Scoop was installed but is not yet in PATH. Please restart your shell."
        exit /b 1
    )
    
    call :print_success "scoop installed."
    exit /b 0

:install_kotlin_sdk
    call :print_info "Installing Kotlin SDK via scoop..."
    call :install_scoop
    if %errorlevel% neq 0 (
        call :print_warning "Scoop is not available. Skipping Kotlin SDK installation."
        exit /b 0
    )
    
    :: Add java bucket for Kotlin
    call :print_info "Adding scoop java bucket..."
    scoop bucket add java 2>nul
    
    call :print_info "Installing Kotlin..."
    scoop install kotlin
    if %errorlevel% neq 0 (
        call :print_warning "Failed to install Kotlin SDK via scoop."
        exit /b 0
    )
    
    call :print_success "Kotlin SDK installed via scoop."
    exit /b 0

:install_kotlin_lsp
    call :print_info "Installing kotlin-lsp..."
    set "KLS_DIR=%USER_HOME%\kotlin-language-server"
    set "ORIGINAL_DIR=%CD%"
    
    if not exist "%KLS_DIR%" (
        git clone https://github.com/fwcd/kotlin-language-server "%KLS_DIR%"
        if %errorlevel% neq 0 (
            call :print_error "Failed to clone kotlin-language-server repository."
            exit /b 1
        )
        
        cd /d "%KLS_DIR%"
        if %errorlevel% neq 0 (
            cd /d "%ORIGINAL_DIR%"
            call :print_error "Failed to change directory to %KLS_DIR%"
            exit /b 1
        )
        
        if not exist "gradlew.bat" (
            cd /d "%ORIGINAL_DIR%"
            call :print_error "gradlew.bat not found in kotlin-language-server repository."
            exit /b 1
        )
        
        call :print_info "Building kotlin-language-server (this may take a while)..."
        call gradlew.bat :server:installDist
        if %errorlevel% neq 0 (
            cd /d "%ORIGINAL_DIR%"
            call :print_error "Failed to build kotlin-language-server."
            exit /b 1
        )
        
        call :print_info "Adding kotlin-language-server to user PATH..."
        set "KLS_BIN=%KLS_DIR%\server\build\install\server\bin"
        
        :: Get current PATH and append new path
        for /f "skip=2 tokens=3*" %%a in ('reg query "HKCU\Environment" /v PATH 2^>nul') do set "CURRENT_PATH=%%b"
        if not defined CURRENT_PATH set "CURRENT_PATH=%PATH%"
        
        :: Check if already in PATH
        echo %CURRENT_PATH% | findstr /C:"%KLS_BIN%" >nul
        if %errorlevel% neq 0 (
            setx PATH "%CURRENT_PATH%;%KLS_BIN%"
            if %errorlevel% neq 0 (
                call :print_warning "Failed to add kotlin-language-server to PATH. Please add %KLS_BIN% to your PATH manually."
            ) else (
                call :print_success "kotlin-lsp installed and added to PATH."
            )
        ) else (
            call :print_success "kotlin-lsp installed (already in PATH)."
        )
        
        cd /d "%ORIGINAL_DIR%"
    ) else (
        call :print_info "kotlin-lsp directory already exists. Skipping clone and build."
    )
    exit /b 0

:install_ripgrep_fd
    call :print_info "Installing ripgrep and fd..."
    winget install --id BurntSushi.Ripgrep.MSVC -e --accept-source-agreements --accept-package-agreements
    if %errorlevel% neq 0 (
        call :print_warning "ripgrep installation failed or was skipped."
    )
    
    winget install --id sharkdp.fd -e --accept-source-agreements --accept-package-agreements
    if %errorlevel% neq 0 (
        call :print_warning "fd installation failed or was skipped."
    )
    
    call :print_success "ripgrep and fd installation completed."
    exit /b 0

:install_nerd_font
    call :print_info "Installing Ubuntu Mono Nerd Font..."
    set "FONT_DIR=%LOCALAPPDATA%\Microsoft\Windows\Fonts"
    set "FONT_FILE=%FONT_DIR%\UbuntuMonoNerdFont-Regular.ttf"
    
    if not exist "%FONT_FILE%" (
        if not exist "%FONT_DIR%" mkdir "%FONT_DIR%"
        set "TMP_ZIP=%TEMP%\UbuntuMono.zip"
        
        call :print_info "Fetching latest Nerd Fonts release..."
        call :get_latest_github_release "ryanoasis/nerd-fonts"
        if not defined LATEST_VERSION (
            call :print_warning "Failed to fetch latest Nerd Fonts version, using fallback v3.1.1"
            set "LATEST_VERSION=v3.1.1"
        )
        
        set "FONT_URL=https://github.com/ryanoasis/nerd-fonts/releases/download/%LATEST_VERSION%/UbuntuMono.zip"
        call :print_info "Downloading Ubuntu Mono Nerd Font %LATEST_VERSION%..."
        curl -fLo "%TMP_ZIP%" "%FONT_URL%"
        if %errorlevel% neq 0 (
            call :print_error "Failed to download Nerd Font from %FONT_URL%"
            exit /b 1
        )
        
        call :print_info "Extracting font files..."
        tar -xf "%TMP_ZIP%" -C "%FONT_DIR%" *.ttf 2>nul
        if %errorlevel% neq 0 (
            :: Fallback to PowerShell if tar fails
            powershell -Command "Expand-Archive -Path '%TMP_ZIP%' -DestinationPath '%FONT_DIR%' -Force"
        )
        del "%TMP_ZIP%"
        
        call :print_info "Registering fonts with Windows..."
        powershell -Command "$fonts = (New-Object -ComObject Shell.Application).Namespace(0x14); Get-ChildItem '%FONT_DIR%\*.ttf' | ForEach-Object { $fonts.CopyHere($_.FullName, 0x10) }" 2>nul
        
        call :print_success "Ubuntu Mono Nerd Font installed."
        call :print_success "You may now set your terminal font to 'UbuntuMono Nerd Font'."
        call :print_info "If the font doesn't appear immediately, try restarting your terminal or logging out and back in."
    ) else (
        call :print_info "Ubuntu Mono Nerd Font already exists. Skipping installation."
    )
    exit /b 0

:install_neovim
    call :print_info "Installing Neovim (latest stable)..."
    
    :: Check if Neovim is already installed with adequate version
    call :command_exists nvim
    if %errorlevel% equ 0 (
        for /f "tokens=2 delims=v. " %%a in ('nvim --version ^| findstr /R "NVIM v[0-9]"') do set NVIM_MAJOR=%%a
        for /f "tokens=3 delims=v. " %%a in ('nvim --version ^| findstr /R "NVIM v[0-9]"') do set NVIM_MINOR=%%a
        
        if defined NVIM_MAJOR if defined NVIM_MINOR (
            if %NVIM_MAJOR% gtr 0 (
                call :print_info "Neovim is already installed with version %NVIM_MAJOR%.%NVIM_MINOR%"
                exit /b 0
            )
            if %NVIM_MAJOR% equ 0 if %NVIM_MINOR% geq 10 (
                call :print_info "Neovim is already installed with version %NVIM_MAJOR%.%NVIM_MINOR%"
                exit /b 0
            )
        )
    )
    
    winget install --id Neovim.Neovim -e --accept-source-agreements --accept-package-agreements
    if %errorlevel% neq 0 (
        call :print_warning "Neovim installation failed or was skipped."
        exit /b 0
    )
    
    call :print_success "Neovim installed."
    exit /b 0

:install_nvim_packages
    call :print_info "Installing nvim packages via Mason..."
    
    :: Check if nvim is available
    call :command_exists nvim
    if %errorlevel% neq 0 (
        call :print_warning "nvim is not available. Please restart your shell and run nvim manually to complete setup."
        exit /b 0
    )
    
    call :print_info "Syncing Lazy plugins..."
    nvim --headless "+Lazy! sync" +qa
    if %errorlevel% neq 0 (
        call :print_warning "Lazy plugin sync encountered issues but continuing..."
    )
    
    call :print_info "Updating Mason registry..."
    nvim --headless "+MasonUpdate" +qa
    if %errorlevel% neq 0 (
        call :print_warning "Mason update encountered issues but continuing..."
    )

    call :print_info "Installing Mason packages (this may take several minutes)..."
    nvim --headless +"lua local pkgs = { 'typescript-language-server', 'angular-language-server', 'jdtls', 'eslint_d', 'prettierd', 'prettier', 'stylua', } local mr = require('mason-registry') mr.refresh() local targets = {} for _, name in ipairs(pkgs) do local ok, p = pcall(mr.get_package, name) if ok and not p:is_installed() then table.insert(targets, p) end end if #targets == 0 then print('All Mason packages are already installed.') return end print('Installing ' .. #targets .. ' Mason package(s)...') local done = 0 local total = #targets for _, p in ipairs(targets) do p:install():on('closed', function() done = done + 1 print(string.format('Progress: %%d/%%d packages installed', done, total)) end) end local result = vim.wait(300000, function() return done == total end, 1000) if not result then print('Warning: Mason package installation timed out after 5 minutes.') print('Some packages may not be fully installed. You can run :MasonInstall manually.') else print('Mason package installation complete.') end" +qa
    
    call :print_success "Nvim packages setup completed."
    exit /b 0

:: --- Main Execution ---
:main
    call :check_admin
    call :print_info "Starting Neovim prerequisites installation for Windows..."

    call :install_winget
    if %errorlevel% neq 0 goto :error
    
    call :install_system_packages
    call :install_fnm_and_node
    call :install_python_packages
    call :install_npm_packages
    call :install_java_sdks
    call :install_kotlin_sdk
    call :install_kotlin_lsp
    call :install_ripgrep_fd
    call :install_nerd_font
    call :install_neovim
    call :install_nvim_packages

    call :print_success "All prerequisites have been installed successfully!"
    call :print_info "IMPORTANT: Please restart your shell or terminal for all PATH changes to take effect."
    call :print_info "After restarting, verify installations by running: nvim --version, node --version, fnm --version"
    exit /b 0

:error
    call :print_error "Installation failed. Please check the error messages above."
    exit /b 1

call :main

endlocal
