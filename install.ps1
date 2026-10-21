[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot
$themeSource = Join-Path $repo 'themes\omarchy-p10k-windows.omp.json'
$profileSource = Join-Path $repo 'profile\OhMyPosh.Windows.ps1'
$themeDir = Join-Path $HOME '.poshthemes'
$themeTarget = Join-Path $themeDir 'omarchy-p10k-windows.omp.json'
$profileTarget = Join-Path $themeDir 'OhMyPosh.Windows.ps1'
$managedStart = '# >>> Omarchy P10k Windows >>>'
$managedEnd = '# <<< Omarchy P10k Windows <<<'

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
if ($profileText -match [regex]::Escape($managedStart)) {
    $pattern = '(?s)' + [regex]::Escape($managedStart) + '.*?' + [regex]::Escape($managedEnd)
    $profileText = [regex]::Replace($profileText, $pattern, '').TrimEnd()
}
$profileBackup = "$PROFILE.omarchy-p10k.bak"
if (Test-Path -LiteralPath $PROFILE) {
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
        $settings = Get-Content -Raw -LiteralPath $settingsPath | ConvertFrom-Json -AsHashtable
        if (-not $settings.ContainsKey('schemes')) { $settings.schemes = @() }
        $scheme = @{
            name = 'Omarchy Blue'
            background = '#0B1220'
            foreground = '#EAF2FF'
            cursorColor = '#FFFFFF'
            selectionBackground = '#264A78'
            black = '#101827'; red = '#F87171'; green = '#4ADE80'; yellow = '#FBBF24'
            blue = '#60A5FA'; purple = '#C4B5FD'; cyan = '#67E8F9'; white = '#EAF2FF'
            brightBlack = '#64748B'; brightRed = '#FCA5A5'; brightGreen = '#86EFAC'
            brightYellow = '#FDE68A'; brightBlue = '#93C5FD'; brightPurple = '#DDD6FE'
            brightCyan = '#A5F3FC'; brightWhite = '#FFFFFF'
        }
        $settings.schemes = @($settings.schemes | Where-Object { $_.name -ne $scheme.name }) + @($scheme)
        if (-not $settings.profiles) { $settings.profiles = @{} }
        if (-not $settings.profiles.defaults) { $settings.profiles.defaults = @{} }
        $settings.profiles.defaults.colorScheme = 'Omarchy Blue'
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
