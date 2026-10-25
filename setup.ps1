[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw 'Ejecuta setup.ps1 desde PowerShell 7 (pwsh).'
}
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'No se encontró winget. Instala App Installer desde Microsoft Store y vuelve a intentarlo.'
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
    & (Join-Path $PSScriptRoot 'install.ps1')
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
    Write-Host '0. Salir'
}

do {
    Show-SetupMenu
    $choice = Read-Host 'Seleccione una opción (0-6)'
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
        '0' { break }
        default { Write-Warning 'Opción no válida.'; Start-Sleep -Seconds 1 }
    }
    if ($choice -ne '0') { Read-Host 'Presiona Enter para volver al menú' }
} while ($choice -ne '0')
