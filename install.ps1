[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot
$themeSource = Join-Path $repo 'themes\winp10k-aurora.omp.json'
$profileSource = Join-Path $repo 'profile\WinP10k-Aurora.ps1'
$themeDir = Join-Path $HOME '.poshthemes'
$themeTarget = Join-Path $themeDir 'winp10k-aurora.omp.json'
$profileTarget = Join-Path $themeDir 'WinP10k-Aurora.ps1'
$managedStart = '# >>> WinP10k Aurora >>>'
$managedEnd = '# <<< WinP10k Aurora <<<'
$managedBlocks = @(
    [PSCustomObject]@{ Start = $managedStart; End = $managedEnd }
    [PSCustomObject]@{ Start = '# >>> Omarchy P10k Windows >>>'; End = '# <<< Omarchy P10k Windows <<<' }
)

if ($PSVersionTable.PSVersion.Major -lt 7) {
    Write-Host 'PowerShell 7 or newer is required. This session is running an older version.'
    $wingetAvailable = [bool](Get-Command winget -ErrorAction SilentlyContinue)
    if ($wingetAvailable -and ((Read-Host 'Install PowerShell 7 with WinGet now? (y/n)') -match '^[YySs]')) {
        winget install --exact --id Microsoft.PowerShell --source winget --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -eq 0) { Write-Host 'Open a new PowerShell 7 session and run install.ps1 again.' }
        else { Write-Warning "PowerShell 7 installation failed (exit code $LASTEXITCODE)." }
    } else {
        Write-Host 'Install PowerShell 7 with winget install --exact --id Microsoft.PowerShell, then reopen this installer in pwsh.'
    }
    throw 'Aurora installation stopped because this session is not PowerShell 7.'
}
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host 'WinGet is required. Install or update App Installer from Microsoft Store, then reopen PowerShell:'
    Write-Host 'https://apps.microsoft.com/detail/9nblggh4nns1'
    throw 'WinGet is missing; Aurora was not installed.'
}

if (-not (Test-Path -LiteralPath $themeSource)) { throw "Theme file is missing: $themeSource" }
if (-not (Test-Path -LiteralPath $profileSource)) { throw "Profile file is missing: $profileSource" }

if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    Write-Host 'Requirement missing: Oh My Posh.'
    if ((Read-Host 'Install Oh My Posh with WinGet now? (y/n)') -notmatch '^[YySs]') {
        throw 'Install Oh My Posh and rerun install.ps1.'
    }
    winget install --exact --id JanDeDobbeleer.OhMyPosh --source winget --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -ne 0) { throw "WinGet could not install Oh My Posh (exit code $LASTEXITCODE)." }
    $machinePath = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = (@($machinePath, $userPath) -join ';')
}
if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    throw 'Oh My Posh se instaló, pero no está disponible en esta sesión. Cierra PowerShell y vuelve a ejecutar install.ps1.'
}
Write-Host 'Requirement OK: Oh My Posh.'

$fontRegistryPaths = @(
    'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts',
    'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
)
$mesloInstalled = $false
foreach ($fontRegistryPath in $fontRegistryPaths) {
    if (Test-Path -LiteralPath $fontRegistryPath) {
        $fontProperties = Get-ItemProperty -LiteralPath $fontRegistryPath
        if (($fontProperties.PSObject.Properties.Name -join "`n") -match 'Meslo.*Nerd') {
            $mesloInstalled = $true
            break
        }
    }
}
if (-not $mesloInstalled) {
    Write-Host 'Requirement missing: Meslo Nerd Font (recommended for Aurora icons).'
    if ((Read-Host 'Install Meslo Nerd Font with Oh My Posh now? (y/n)') -match '^[YySs]') {
        & oh-my-posh font install meslo
        if ($LASTEXITCODE -ne 0) { Write-Warning 'Font installation failed. Retry with: oh-my-posh font install meslo' }
    } else {
        Write-Warning 'Aurora can still be installed, but some symbols may display as squares.'
    }
} else {
    Write-Host 'Requirement OK: Meslo Nerd Font.'
}

if (-not (Get-Command wt.exe -ErrorAction SilentlyContinue)) {
    Write-Host 'Optional: Windows Terminal was not detected.'
    if ((Read-Host 'Install Windows Terminal with WinGet now? (y/n)') -match '^[YySs]') {
        winget install --exact --id Microsoft.WindowsTerminal --source winget --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -ne 0) { Write-Warning 'Windows Terminal installation failed; continuing without its settings integration.' }
    }
}

New-Item -ItemType Directory -Force -Path $themeDir | Out-Null
Copy-Item -LiteralPath $themeSource -Destination $themeTarget -Force
Copy-Item -LiteralPath $profileSource -Destination $profileTarget -Force
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $PROFILE) | Out-Null
if (Test-Path -LiteralPath $PROFILE) {
    $profileText = Get-Content -Raw -LiteralPath $PROFILE
} else {
    $profileText = ''
}
foreach ($managedBlock in $managedBlocks) {
    if ($profileText -match [regex]::Escape($managedBlock.Start)) {
        $pattern = '(?s)' + [regex]::Escape($managedBlock.Start) + '.*?' + [regex]::Escape($managedBlock.End)
        $profileText = [regex]::Replace($profileText, $pattern, '').TrimEnd()
    }
}
$profileBackup = "$PROFILE.winp10k-aurora.bak"
if ((Test-Path -LiteralPath $PROFILE) -and -not (Test-Path -LiteralPath $profileBackup)) {
    Copy-Item -LiteralPath $PROFILE -Destination $profileBackup -Force
}
$block = @"
$managedStart
. '$profileTarget'
$managedEnd
"@
$newline = [Environment]::NewLine
Set-Content -LiteralPath $PROFILE -Value (($profileText.TrimEnd() + $newline + $newline + $block).Trim() + $newline) -Encoding utf8
Write-Host "Perfil actualizado. Copia de seguridad: $profileBackup"

try {
    oh-my-posh font install meslo
} catch {
    Write-Warning 'No se pudo instalar Meslo automáticamente. Ejecuta: oh-my-posh font install meslo'
}

$settingsCandidates = @(
    (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'),
    (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json')
)
$settingsPath = $settingsCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if ($settingsPath) {
    try {
        $settingsBackup = "$settingsPath.winp10k-aurora.bak"
        if (-not (Test-Path -LiteralPath $settingsBackup)) {
            Copy-Item -LiteralPath $settingsPath -Destination $settingsBackup
        }
        $settings = Get-Content -Raw -LiteralPath $settingsPath | ConvertFrom-Json -AsHashtable
        if (-not $settings.ContainsKey('schemes')) { $settings.schemes = @() }
        $scheme = @{
            name = 'WinP10k Aurora'
            background = '#0B1220'
            foreground = '#EAF2FF'
            cursorColor = '#FFFFFF'
            selectionBackground = '#264A78'
            black = '#101827'; red = '#FF3B30'; green = '#00E676'; yellow = '#FFD740'
            blue = '#0078D4'; purple = '#C4B5FD'; cyan = '#00E5FF'; white = '#EAF2FF'
            brightBlack = '#64748B'; brightRed = '#FF6B6B'; brightGreen = '#69F0AE'
            brightYellow = '#FFE57F'; brightBlue = '#40A9FF'; brightPurple = '#DDD6FE'
            brightCyan = '#84FFFF'; brightWhite = '#FFFFFF'
        }
        $settings.schemes = @($settings.schemes | Where-Object { $_.name -ne $scheme.name }) + @($scheme)
        if (-not $settings.profiles) { $settings.profiles = @{} }
        if (-not $settings.profiles.defaults) { $settings.profiles.defaults = @{} }
        $settings.profiles.defaults.colorScheme = 'WinP10k Aurora'
        if (-not $settings.profiles.defaults.font) { $settings.profiles.defaults.font = @{} }
        $settings.profiles.defaults.font.face = 'MesloLGM Nerd Font'
        $settings | ConvertTo-Json -Depth 100 | Set-Content -LiteralPath $settingsPath -Encoding utf8
        Write-Host "Windows Terminal configurado: $settingsPath"
    } catch {
        Write-Warning "No se pudo actualizar Windows Terminal automáticamente: $($_.Exception.Message)"
    }
} else {
    Write-Host 'No se detectó Windows Terminal; su esquema azul se puede configurar más adelante.'
}

Write-Host 'Instalación lista. Reinicia Windows Terminal para cargar el tema y la fuente.'


