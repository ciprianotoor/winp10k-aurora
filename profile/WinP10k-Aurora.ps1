# WinP10k Aurora: datos de red y prompt para PowerShell 7.
# Se obtienen todas las IPv4 en una sola consulta para reducir el trabajo al iniciar.
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

oh-my-posh init pwsh --config "$HOME\.poshthemes\winp10k-aurora.omp.json" | Invoke-Expression

# Actualiza el segmento de último comando sin añadir lógica al JSON del tema.
$global:WinP10kAuroraBasePrompt = (Get-Command prompt).ScriptBlock
function global:prompt {
    $historyEntry = Get-History -Count 1
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
