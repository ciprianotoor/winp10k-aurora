# WinP10k Aurora: datos de red y prompt para PowerShell 7.
# Se obtienen todas las IPv4 en una sola consulta para reducir el trabajo al iniciar.
$privacyConfigPath = Join-Path $env:LOCALAPPDATA 'WinP10kAurora\profile.json'
$showNetworkAddresses = $true
$global:WinP10kAuroraShowLastCommand = $true
if (Test-Path -LiteralPath $privacyConfigPath) {
    try {
        $privacyConfig = Get-Content -Raw -LiteralPath $privacyConfigPath | ConvertFrom-Json
        if ($null -ne $privacyConfig.ShowNetworkAddresses) {
            $showNetworkAddresses = [bool]$privacyConfig.ShowNetworkAddresses
        }
        if ($null -ne $privacyConfig.ShowLastCommand) {
            $global:WinP10kAuroraShowLastCommand = [bool]$privacyConfig.ShowLastCommand
        }
    } catch {
        Write-Warning 'No se pudo leer la configuracion de privacidad de WinP10k Aurora.'
    }
}

$addresses = @(
    Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object {
            $_.IPAddress -notmatch '^(127\.|169\.254\.)'
        }
)

$defaultRoute = Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction SilentlyContinue |
    Where-Object { $_.NextHop -and $_.NextHop -ne '0.0.0.0' } |
    Sort-Object RouteMetric, InterfaceMetric |
    Select-Object -First 1

$privateIpPattern = '^(192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)'
$lanCandidates = $addresses | Where-Object { $_.InterfaceAlias -notmatch 'Tailscale|Loopback' }
$lanAddress = if ($defaultRoute) {
    $lanCandidates | Where-Object {
        $_.InterfaceAlias -eq $defaultRoute.InterfaceAlias -and
        $_.IPAddress -match $privateIpPattern
    } | Select-Object -First 1
}
if (-not $lanAddress) {
    $lanAddress = $lanCandidates | Where-Object { $_.IPAddress -match $privateIpPattern } |
        Sort-Object InterfaceMetric, SkipAsSource |
        Select-Object -First 1
}

$tailscaleAddress = $addresses |
    Where-Object { $_.IPAddress -match '^100\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\.' } |
    Select-Object -First 1

$env:IP_LOCAL = if ($lanAddress) { $lanAddress.IPAddress } else { '' }
$env:IP_TAILSCALE = if ($tailscaleAddress) { $tailscaleAddress.IPAddress } else { '' }
if (-not $showNetworkAddresses) {
    $env:IP_LOCAL = ''
    $env:IP_TAILSCALE = ''
}

oh-my-posh init pwsh --config "$HOME\.poshthemes\winp10k-aurora.omp.json" | Invoke-Expression

# Actualiza el segmento de último comando sin añadir lógica al JSON del tema.
$global:WinP10kAuroraBasePrompt = (Get-Command prompt).ScriptBlock
function global:prompt {
    $historyEntry = if ($global:WinP10kAuroraShowLastCommand) { Get-History -Count 1 } else { $null }
    $lastCommand = if ($historyEntry) {
        ($historyEntry.CommandLine -replace '\s+', ' ').Trim()
    } else {
        ''
    }
    if ($lastCommand.Length -gt 34) {
        $lastCommand = $lastCommand.Substring(0, 31) + '...'
    }

    $env:POSH_LAST_COMMAND = $lastCommand
    & $global:WinP10kAuroraBasePrompt
}

# Carga solo las mejoras instaladas por setup.ps1.
Import-Module PSReadLine -ErrorAction SilentlyContinue
foreach ($moduleName in @('Terminal-Icons', 'PSFzf', 'CompletionPredictor')) {
    if (Get-Module -ListAvailable -Name $moduleName) {
        Import-Module $moduleName -ErrorAction SilentlyContinue
    }
}

if (Get-Module PSReadLine) {
    try {
        $predictionSource = if (Get-Module CompletionPredictor) { 'HistoryAndPlugin' } else { 'History' }
        Set-PSReadLineOption -PredictionSource $predictionSource -PredictionViewStyle ListView
        Set-PSReadLineOption -BellStyle None -EditMode Windows
        Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
        Set-PSReadLineKeyHandler -Chord Ctrl+d -Function DeleteChar
        Set-PSReadLineKeyHandler -Chord Ctrl+Backspace -Function BackwardKillWord
        Set-PSReadLineKeyHandler -Chord Ctrl+Delete -Function KillWord
    } catch {
        # Keep the profile usable if the installed PSReadLine lacks prediction support.
    }
}

if (Get-Module PSFzf) {
    try {
        Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
    } catch {
        # PSFzf stays optional when a terminal does not support its key bindings.
    }
}

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& zoxide init powershell)
}

Set-Alias ll Get-ChildItem -Scope Global -Force
Set-Alias la Get-ChildItem -Scope Global -Force
if (Get-Command bat -ErrorAction SilentlyContinue) { Set-Alias cat bat -Scope Global -Force }
if (Get-Command rg -ErrorAction SilentlyContinue) { Set-Alias grep rg -Scope Global -Force }
