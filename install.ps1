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
    throw 'Ejecuta este instalador desde PowerShell 7 (pwsh).'
}
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'No se encontró winget. Instala App Installer desde Microsoft Store y vuelve a intentarlo.'
}

if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    Write-Host 'Instalando Oh My Posh con winget...'
    winget install --id JanDeDobbeleer.OhMyPosh --source winget --accept-source-agreements --accept-package-agreements
    $env:Path = [Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' +
        [Environment]::GetEnvironmentVariable('Path', 'User')
}
if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    throw 'Oh My Posh se instaló, pero no está disponible en esta sesión. Cierra PowerShell y vuelve a ejecutar install.ps1.'
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


