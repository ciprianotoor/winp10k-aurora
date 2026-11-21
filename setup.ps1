[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host 'PowerShell 7 or newer is required. This session is running an older version.'
    $wingetAvailable = [bool](Get-Command winget -ErrorAction SilentlyContinue)
    if ($wingetAvailable -and ((Read-Host 'Install PowerShell 7 with WinGet now? (y/n)') -match '^[YySs]')) {
        winget install --exact --id Microsoft.PowerShell --source winget --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -eq 0) { Write-Host 'Open a new PowerShell 7 session and run setup.ps1 again.' }
        else { Write-Warning "PowerShell 7 installation failed (exit code $LASTEXITCODE)." }
    } else {
        Write-Host 'Install PowerShell 7 with winget install --exact --id Microsoft.PowerShell, then reopen this installer in pwsh.'
    }
    throw 'Setup stopped because this session is not PowerShell 7.'
}
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host 'WinGet is missing. Install or update App Installer from Microsoft Store, then reopen PowerShell:'
    Write-Host 'https://apps.microsoft.com/detail/9nblggh4nns1'
    throw 'WinGet is required to install the selected applications.'
}

function Read-SetupValue {
    param([string]$Prompt, [string]$Default = '')
    if ($Default) {
        $value = Read-Host "$Prompt [$Default]"
        if (-not $value) { return $Default }
        return $value.Trim()
    }
    do { $value = (Read-Host $Prompt).Trim() } while (-not $value)
    return $value
}

function Install-WinGetPackage {
    param([Parameter(Mandatory)][string]$Id)
    Write-Host "Instalando $Id..."
    winget install --exact --id $Id --source winget --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "winget no pudo instalar $Id. Revisa el mensaje anterior y vuelve a intentarlo."
        return $false
    }
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $currentPaths = @($env:Path -split ';' | Where-Object { $_ })
    $availablePaths = "$machinePath;$userPath" -split ';' | Where-Object { $_ }
    $newPaths = @($availablePaths | Where-Object { $currentPaths -notcontains $_ })
    $env:Path = (@($currentPaths) + @($newPaths)) -join ';'
    return $true
}

function Install-Prompt {
    if ($PSVersionTable.PSVersion.Major -lt 7) {
        throw 'PowerShell 7 is required. Install Microsoft.PowerShell and reopen setup.ps1 in pwsh.'
    }
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host 'WinGet is missing. Install or update App Installer from Microsoft Store, then reopen PowerShell:'
        Write-Host 'https://apps.microsoft.com/detail/9nblggh4nns1'
        return
    }

    Write-Host 'Checking Aurora requirements:'
    Write-Host '  PowerShell 7: OK'
    Write-Host '  WinGet: OK'
    if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
        Write-Host '  Oh My Posh: missing'
        if ((Read-Host 'Install Oh My Posh now? (y/n)') -notmatch '^[YySs]') { return }
        if (-not (Install-WinGetPackage -Id 'JanDeDobbeleer.OhMyPosh')) { return }
    } else {
        Write-Host '  Oh My Posh: OK'
    }

    if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
        Write-Warning 'Oh My Posh is installed but unavailable in this session. Reopen PowerShell and run setup.ps1 again.'
        return
    }

    $fontRegistryPaths = @(
        'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts',
        'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
    )
    $mesloInstalled = $false
    foreach ($fontRegistryPath in $fontRegistryPaths) {
        if (Test-Path $fontRegistryPath) {
            $fontProperties = Get-ItemProperty -LiteralPath $fontRegistryPath
            if (($fontProperties.PSObject.Properties.Name -join "`n") -match 'Meslo.*Nerd') {
                $mesloInstalled = $true
                break
            }
        }
    }
    if ($mesloInstalled) {
        Write-Host '  Meslo Nerd Font: OK'
    } else {
        Write-Host '  Meslo Nerd Font: missing'
        if ((Read-Host 'Install Meslo Nerd Font now? (y/n)') -notmatch '^[YySs]') {
            Write-Warning 'Aurora will install, but its icons may appear as squares until a Nerd Font is installed.'
        } else {
            Write-Host 'Installing Meslo Nerd Font...'
            & oh-my-posh font install meslo
            if ($LASTEXITCODE -ne 0) {
                Write-Warning 'Font installation failed. You can retry with: oh-my-posh font install meslo'
            }
        }
    }

    if (-not (Get-Command wt.exe -ErrorAction SilentlyContinue)) {
        Write-Host '  Windows Terminal: not detected (optional)'
        if ((Read-Host 'Install Windows Terminal? (y/n)') -match '^[YySs]') {
            Install-WinGetPackage -Id 'Microsoft.WindowsTerminal' | Out-Null
        }
    } else {
        Write-Host '  Windows Terminal: OK'
    }

    & (Join-Path $PSScriptRoot 'install.ps1')
}

function Ensure-GitTool {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        if ((Read-Host 'Git is required for repository operations. Install Git now? (y/n)') -notmatch '^[YySs]') { return $false }
        if (-not (Install-WinGetPackage -Id 'Git.Git')) { return $false }
    }
    return [bool](Get-Command git -ErrorAction SilentlyContinue)
}

function Ensure-GitHubTools {
    if (-not (Ensure-GitTool)) { return $false }
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        if ((Read-Host 'GitHub CLI is required for account setup. Install it now? (y/n)') -notmatch '^[YySs]') { return $false }
        if (-not (Install-WinGetPackage -Id 'GitHub.cli')) { return $false }
    }
    $gitAvailable = [bool](Get-Command git -ErrorAction SilentlyContinue)
    $ghAvailable = [bool](Get-Command gh -ErrorAction SilentlyContinue)
    return ($gitAvailable -and $ghAvailable)
}

function Get-RepositoryRoot {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { return $null }
    $root = (& git -C $PSScriptRoot rev-parse --show-toplevel 2>$null | Select-Object -First 1)
    if ($LASTEXITCODE -ne 0 -or -not $root) { return $null }
    return $root.Trim()
}

function Update-RepositoryFromGitHub {
    if (-not (Ensure-GitTool)) { return }
    $root = Get-RepositoryRoot
    if (-not $root) {
        Write-Warning 'This folder is not a Git clone. Downloaded ZIP folders cannot pull updates. Clone https://github.com/ciprianotoor/winp10k-aurora.git to enable updates.'
        return
    }
    $changes = & git -C $root status --porcelain
    if ($LASTEXITCODE -ne 0) { Write-Warning 'Could not read Git status.'; return }
    if ($changes) {
        Write-Warning 'Local changes are present. Commit or publish them before pulling, so the update does not overwrite your work.'
        & git -C $root status --short
        return
    }
    & git -C $root remote -v
    if ((Read-Host 'Pull updates from the configured GitHub remote using fast-forward only? (y/n)') -notmatch '^[YySs]') { return }
    & git -C $root pull --ff-only
    if ($LASTEXITCODE -ne 0) { Write-Warning 'Git could not fast-forward. Review the repository status and resolve it manually.'; return }
    Write-Host 'Repository updated. Run install.ps1 to apply the Aurora theme/profile files.'
}

function Configure-GitHubAccount {
    if (-not (Ensure-GitHubTools)) { return }
    $root = Get-RepositoryRoot
    if (-not $root) {
        Write-Warning 'Clone the repository first to set its local Git identity and remote.'
        return
    }
    $accountName = (& gh api user --jq .login 2>$null | Select-Object -First 1)
    if ($LASTEXITCODE -eq 0 -and $accountName) {
        Write-Host "Active GitHub account: $accountName"
        if ((Read-Host 'Use this personal account? (y/n)') -notmatch '^[YySs]') {
            & gh auth switch --hostname github.com
            if ($LASTEXITCODE -ne 0) {
                if ((Read-Host 'No other saved account was selected. Sign in to another account in the browser? (y/n)') -notmatch '^[YySs]') { return }
                & gh auth login --hostname github.com --git-protocol https --web
                if ($LASTEXITCODE -ne 0) { Write-Warning 'GitHub sign-in did not complete.'; return }
            }
            $accountName = (& gh api user --jq .login 2>$null | Select-Object -First 1)
        }
    } else {
        if ((Read-Host 'Sign in to your personal GitHub account using the browser flow? (y/n)') -match '^[YySs]') {
            & gh auth login --hostname github.com --git-protocol https --web
            if ($LASTEXITCODE -ne 0) { Write-Warning 'GitHub sign-in did not complete.'; return }
            $accountName = (& gh api user --jq .login 2>$null | Select-Object -First 1)
        } else { return }
    }
    $currentName = (& git -C $root config --local user.name 2>$null | Select-Object -First 1)
    $currentEmail = (& git -C $root config --local user.email 2>$null | Select-Object -First 1)
    if ($currentName) {
        $gitName = Read-Host "Git commit name for this repository [$currentName] (Enter keeps current)"
        if (-not $gitName) { $gitName = $currentName }
    } else {
        do { $gitName = (Read-Host 'Git commit name for this repository (required)').Trim() } while (-not $gitName)
    }
    if ($currentEmail) {
        $gitEmail = Read-Host "Git commit email for this repository [$currentEmail] (Enter keeps current)"
        if (-not $gitEmail) { $gitEmail = $currentEmail }
    } else {
        do { $gitEmail = (Read-Host 'Git commit email for this repository (required)').Trim() } while (-not $gitEmail)
    }
    & git -C $root config --local user.name $gitName
    if ($LASTEXITCODE -ne 0) { Write-Warning 'Could not save the repository-local Git name.'; return }
    & git -C $root config --local user.email $gitEmail
    if ($LASTEXITCODE -ne 0) { Write-Warning 'Could not save the repository-local Git email.'; return }
    if ($accountName) { Write-Host "Authenticated GitHub account: $accountName" }
    Write-Host 'GitHub CLI is authenticated and this repository has a local commit identity.'
    Write-Host 'No password or token is requested or written by this setup.'
    $personalRemote = (& git -C $root remote get-url personal 2>$null | Select-Object -First 1)
    if ($LASTEXITCODE -eq 0 -and $personalRemote) {
        Write-Host "Personal remote already configured: $personalRemote"
    } elseif ((Read-Host "Create a personal fork of ciprianotoor/winp10k-aurora and add it as remote 'personal'? (y/n)") -match '^[YySs]') {
        & gh repo fork ciprianotoor/winp10k-aurora --clone=false --remote --remote-name personal
        if ($LASTEXITCODE -ne 0) { Write-Warning 'Fork creation failed. Check the authenticated account and repository permissions.' }
    }
}

function Publish-RepositoryChanges {
    if (-not (Ensure-GitHubTools)) { return }
    $root = Get-RepositoryRoot
    if (-not $root) { Write-Warning 'Clone the repository first; a ZIP folder cannot publish changes.'; return }
    & gh auth status
    if ($LASTEXITCODE -ne 0) {
        Write-Warning 'Sign in first with the GitHub account option.'
        return
    }
    & git -C $root status --short
    if ($LASTEXITCODE -ne 0) { return }
    & git -C $root remote -v
    $remoteName = Read-Host 'Remote name to publish to [origin]'
    if (-not $remoteName) { $remoteName = 'origin' }
    $remoteUrl = (& git -C $root remote get-url $remoteName 2>$null | Select-Object -First 1)
    if ($LASTEXITCODE -ne 0 -or -not $remoteUrl) { Write-Warning "Remote '$remoteName' does not exist."; return }
    Write-Host "Target: $remoteName -> $remoteUrl"
    $untrackedFiles = @(& git -C $root ls-files --others --exclude-standard)
    foreach ($untrackedFile in $untrackedFiles) {
        if ((Read-Host "Stage new file '$untrackedFile'? (y/n)") -match '^[YySs]') {
            & git -C $root add -- $untrackedFile
            if ($LASTEXITCODE -ne 0) { Write-Warning "Could not stage $untrackedFile."; return }
        }
    }
    if ((Read-Host 'Stage changes interactively with git add -p? (y/n)') -notmatch '^[YySs]') { return }
    & git -C $root add -p
    if ($LASTEXITCODE -ne 0) { Write-Warning 'Interactive staging failed.'; return }
    $stagedFiles = @(& git -C $root diff --cached --name-only)
    if (-not $stagedFiles) { Write-Warning 'No changes were staged.'; return }
    & git -C $root diff --cached --check
    if ($LASTEXITCODE -ne 0) { Write-Warning 'Staged changes have whitespace errors; review before committing.'; return }
    & git -C $root diff --cached --stat
    $message = Read-Host 'Commit message (leave blank to cancel)'
    if (-not $message) { return }
    if ((Read-Host "Commit the staged changes as '$message'? (y/n)") -notmatch '^[YySs]') { return }
    & git -C $root commit -m $message
    if ($LASTEXITCODE -ne 0) { Write-Warning 'Commit failed.'; return }
    if ((Read-Host "Push this commit to $remoteName now? (y/n)") -notmatch '^[YySs]') { return }
    & git -C $root push $remoteName HEAD
    if ($LASTEXITCODE -ne 0) { Write-Warning 'Push failed. Your commit remains local.'; return }
    Write-Host 'Changes published to GitHub.'
}

function Show-CodingAssistantPrompt {
    $promptPath = Join-Path $PSScriptRoot 'PROMPT-CODEX-COPILOT.md'
    if (-not (Test-Path -LiteralPath $promptPath)) { Write-Warning "Prompt file not found: $promptPath"; return }
    Get-Content -LiteralPath $promptPath
    if (Get-Command Set-Clipboard -ErrorAction SilentlyContinue) {
        if ((Read-Host 'Copy the prompt to the clipboard? (y/n)') -match '^[YySs]') {
            Get-Content -Raw -LiteralPath $promptPath | Set-Clipboard
            Write-Host 'Prompt copied.'
        }
    }
}

function Show-GitHubMenu {
    do {
        Write-Host '1. Update this clone from GitHub (fast-forward only)'
        Write-Host '2. Sign in and configure this repository for a personal GitHub account'
        Write-Host '3. Review, commit, and optionally push local changes'
        Write-Host '0. Back'
        $githubChoice = Read-Host 'Choose an option (0-3)'
        switch ($githubChoice) {
            '1' { Update-RepositoryFromGitHub }
            '2' { Configure-GitHubAccount }
            '3' { Publish-RepositoryChanges }
            '0' { break }
            default { Write-Warning 'Invalid option.' }
        }
        if ($githubChoice -ne '0') { Read-Host 'Press Enter to return to the GitHub menu' }
    } while ($githubChoice -ne '0')
}

function Install-CommandLineTools {
    $apps = @(
        [PSCustomObject]@{ Name = 'Git'; Id = 'Git.Git' }
        [PSCustomObject]@{ Name = 'Windows Terminal'; Id = 'Microsoft.WindowsTerminal' }
        [PSCustomObject]@{ Name = 'fzf'; Id = 'junegunn.fzf' }
        [PSCustomObject]@{ Name = 'ripgrep (rg)'; Id = 'BurntSushi.ripgrep.MSVC' }
        [PSCustomObject]@{ Name = 'bat'; Id = 'sharkdp.bat' }
        [PSCustomObject]@{ Name = 'zoxide'; Id = 'ajeetdsouza.zoxide' }
        [PSCustomObject]@{ Name = 'GitHub CLI'; Id = 'GitHub.cli' }
        [PSCustomObject]@{ Name = 'Tailscale'; Id = 'Tailscale.Tailscale' }
        [PSCustomObject]@{ Name = 'Midnight Commander (gestor de archivos de dos paneles)'; Id = 'GNU.MidnightCommander' }
        [PSCustomObject]@{ Name = 'Cliamp (reproductor de música para terminal)'; Id = 'Bjarneo.Cliamp' }
        [PSCustomObject]@{ Name = 'GNU nano (editor de texto para terminal)'; Id = 'ChawyeHsu.Nano' }
    )

    foreach ($app in $apps) {
        if ((Read-Host "¿Instalar $($app.Name)? (s/n)") -match '^[Ss]') {
            Install-WinGetPackage -Id $app.Id | Out-Null
        }
    }
}

function Install-PowerShellModules {
    foreach ($name in @('Terminal-Icons', 'PSFzf', 'CompletionPredictor')) {
        if (Get-Module -ListAvailable -Name $name) {
            Write-Host "$name ya está instalado."
            continue
        }
        if ((Read-Host "¿Instalar el módulo $name desde PowerShell Gallery? (s/n)") -match '^[Ss]') {
            Install-Module -Name $name -Repository PSGallery -Scope CurrentUser
        }
    }
}

function Add-ProxmoxSshAlias {
    param(
        [Parameter(Mandatory)][string]$AliasName,
        [Parameter(Mandatory)][string]$HostName,
        [Parameter(Mandatory)][string]$LinuxUser,
        [Parameter(Mandatory)][int]$Port
    )

    $sshDirectory = Join-Path $HOME '.ssh'
    $sshConfig = Join-Path $sshDirectory 'config'
    New-Item -ItemType Directory -Force -Path $sshDirectory | Out-Null
    $content = if (Test-Path -LiteralPath $sshConfig) {
        Get-Content -Raw -LiteralPath $sshConfig
    } else { '' }

    $aliasExists = $false
    foreach ($line in ($content -split "`r?`n")) {
        if ($line -match '^\s*Host\s+(.+)$' -and (($Matches[1] -split '\s+') -contains $AliasName)) {
            $aliasExists = $true
            break
        }
    }
    if ($aliasExists) {
        Write-Host "El alias SSH '$AliasName' ya existe; se conserva sin cambios."
        return
    }

    if (Test-Path -LiteralPath $sshConfig) {
        $backup = "$sshConfig.winp10k-aurora-$(Get-Date -Format 'yyyyMMdd-HHmmss').bak"
        Copy-Item -LiteralPath $sshConfig -Destination $backup
        Write-Host "Copia de seguridad SSH: $backup"
    }
    $block = "# WinP10k Aurora Proxmox`r`nHost $AliasName`r`n    HostName $HostName`r`n    User $LinuxUser`r`n    Port $Port`r`n`r`n"
    [System.IO.File]::WriteAllText($sshConfig, $block + $content, [System.Text.UTF8Encoding]::new($false))
    Write-Host "Se agregó el alias SSH '$AliasName' al inicio de $sshConfig."
}

function Configure-Proxmox {
    if (-not (Get-Command totp-cli -ErrorAction SilentlyContinue)) {
        if ((Read-Host '¿Instalar totp-cli para generar el OTP localmente? (s/n)') -match '^[Ss]') {
            Install-WinGetPackage -Id 'yitsushi.totp-cli' | Out-Null
        }
    }

    $aliasName = Read-SetupValue 'Alias SSH que usarás' 'proxmox'
    $hostAddress = Read-SetupValue 'IP o nombre DNS de Proxmox (Wake-on-LAN y web)'
    $macAddress = Read-SetupValue 'Dirección MAC de la interfaz que recibe Wake-on-LAN'
    $broadcastAddress = Read-SetupValue 'Dirección broadcast de tu red' '255.255.255.255'
    $webPortText = Read-SetupValue 'Puerto de la interfaz web' '8006'
    $wakePortText = Read-SetupValue 'Puerto Wake-on-LAN' '9'
    $sshHostName = Read-SetupValue 'Host o IP para SSH' $hostAddress
    $linuxUser = Read-SetupValue 'Usuario Linux para SSH'
    $sshPortText = Read-SetupValue 'Puerto SSH' '22'
    $otpNamespace = Read-SetupValue 'Espacio de totp-cli' 'proxmox'
    $otpAccount = Read-SetupValue 'Nombre de cuenta en totp-cli' 'proxmox'

    if ($aliasName -notmatch '^[A-Za-z0-9._-]+$') { throw 'El alias SSH solo puede tener letras, números, punto, guion y guion bajo.' }
    if ($hostAddress -notmatch '^[A-Za-z0-9.:%_-]+$' -or $sshHostName -notmatch '^[A-Za-z0-9.:%_-]+$') { throw 'Usa un nombre DNS o una dirección IP válida.' }
    if ($broadcastAddress -notmatch '^[A-Za-z0-9.:%_-]+$') { throw 'Usa una dirección broadcast válida.' }
    if ($linuxUser -notmatch '^[A-Za-z0-9._-]+$') { throw 'El usuario Linux tiene caracteres no válidos.' }
    if ($otpNamespace -notmatch '^[A-Za-z0-9._-]+$' -or $otpAccount -notmatch '^[A-Za-z0-9._-]+$') { throw 'El espacio y el nombre de cuenta OTP solo pueden tener letras, números, punto, guion y guion bajo.' }
    if ($macAddress -notmatch '^([0-9A-Fa-f]{2}[:-]){5}[0-9A-Fa-f]{2}$') { throw 'La MAC debe tener el formato AA-BB-CC-DD-EE-FF.' }
    foreach ($number in @($webPortText, $wakePortText, $sshPortText)) {
        $parsed = 0
        if (-not [int]::TryParse($number, [ref]$parsed) -or $parsed -lt 1 -or $parsed -gt 65535) { throw 'Los puertos deben estar entre 1 y 65535.' }
    }

    Add-ProxmoxSshAlias -AliasName $aliasName -HostName $sshHostName -LinuxUser $linuxUser -Port ([int]$sshPortText)

    $configDirectory = Join-Path $env:LOCALAPPDATA 'WinP10kAurora'
    New-Item -ItemType Directory -Force -Path $configDirectory | Out-Null
    $config = [ordered]@{
        SshAlias = $aliasName
        HostAddress = $hostAddress
        MacAddress = $macAddress
        BroadcastAddress = $broadcastAddress
        WebPort = [int]$webPortText
        WakePort = [int]$wakePortText
        OtpNamespace = $otpNamespace
        OtpAccount = $otpAccount
    }
    $configPath = Join-Path $configDirectory 'proxmox.json'
    if (Test-Path -LiteralPath $configPath) {
        $backup = "$configPath.$(Get-Date -Format 'yyyyMMdd-HHmmss').bak"
        Copy-Item -LiteralPath $configPath -Destination $backup
        Write-Host "Copia de seguridad de la configuración: $backup"
    }
    $config | ConvertTo-Json | Set-Content -LiteralPath $configPath -Encoding utf8NoBOM
    Write-Host "Configuración local guardada en $configPath. No contiene el secreto OTP."

    $moduleSource = Join-Path $PSScriptRoot 'profile\Modules\WinP10k.Proxmox\WinP10k.Proxmox.psm1'
    $documents = [Environment]::GetFolderPath('MyDocuments')
    $moduleDirectory = Join-Path $documents 'PowerShell\Modules\WinP10k.Proxmox'
    New-Item -ItemType Directory -Force -Path $moduleDirectory | Out-Null
    Copy-Item -LiteralPath $moduleSource -Destination (Join-Path $moduleDirectory 'WinP10k.Proxmox.psm1') -Force
    Import-Module -Name (Join-Path $moduleDirectory 'WinP10k.Proxmox.psm1') -Force

    if (Get-Command totp-cli -ErrorAction SilentlyContinue) {
        if ((Read-Host "¿Registrar el secreto TOTP ahora con 'totp-cli add-token $otpNamespace $otpAccount'? (s/n)") -match '^[Ss]') {
            & totp-cli add-token $otpNamespace $otpAccount
        }
    } else {
        Write-Warning 'Instala totp-cli y registra el token manualmente antes de usar el menú.'
    }
}

function Configure-PromptPrivacy {
    $showLastCommand = (Read-Host '¿Mostrar el ultimo comando en el prompt? (s/n)') -match '^[Ss]'
    $showNetwork = (Read-Host '¿Mostrar las direcciones LAN y Tailscale en el prompt? (s/n)') -match '^[Ss]'
    $configDirectory = Join-Path $env:LOCALAPPDATA 'WinP10kAurora'
    New-Item -ItemType Directory -Force -Path $configDirectory | Out-Null
    $settings = [ordered]@{
        ShowLastCommand = $showLastCommand
        ShowNetworkAddresses = $showNetwork
    }
    $configPath = Join-Path $configDirectory 'profile.json'
    $settings | ConvertTo-Json | Set-Content -LiteralPath $configPath -Encoding utf8NoBOM
    Write-Host "Preferencias guardadas en $configPath. Reinicia PowerShell para aplicarlas."
}

function Show-SetupMenu {
    Clear-Host
    Write-Host '====================================' -ForegroundColor Cyan
    Write-Host ' Configuración de WinP10k Aurora' -ForegroundColor Cyan
    Write-Host '====================================' -ForegroundColor Cyan
    Write-Host '1. Instalar el tema, la fuente y configurar Windows Terminal'
    Write-Host '2. Elegir e instalar herramientas de consola'
    Write-Host '3. Elegir e instalar módulos de PowerShell'
    Write-Host '4. Configurar SSH, Wake-on-LAN y OTP de Proxmox'
    Write-Host '5. Configurar privacidad del prompt'
    Write-Host '6. Ejecutar todos los pasos'
    Write-Host '7. GitHub: actualizar clon, configurar cuenta o publicar cambios'
    Write-Host '8. Mostrar/copiar el prompt para Codex o Copilot'
    Write-Host '0. Salir'
}

do {
    Show-SetupMenu
    $choice = Read-Host 'Seleccione una opción (0-8)'
    switch ($choice) {
        '1' { Install-Prompt }
        '2' { Install-CommandLineTools }
        '3' { Install-PowerShellModules }
        '4' { Configure-Proxmox }
        '5' { Configure-PromptPrivacy }
        '6' {
            Install-Prompt
            Install-CommandLineTools
            Install-PowerShellModules
            Configure-Proxmox
            Configure-PromptPrivacy
        }
        '7' { Show-GitHubMenu }
        '8' { Show-CodingAssistantPrompt }
        '0' { break }
        default { Write-Warning 'Opción no válida.'; Start-Sleep -Seconds 1 }
    }
    if ($choice -ne '0') { Read-Host 'Presiona Enter para volver al menú' }
} while ($choice -ne '0')
