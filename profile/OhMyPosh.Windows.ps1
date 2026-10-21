# Omarchy P10k Windows: información opcional mostrada por el tema.
# Se mantiene separado del perfil personal del usuario.
$lan = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object {
        $_.IPAddress -notlike '127.*' -and
        $_.IPAddress -notlike '169.254.*' -and
        $_.InterfaceAlias -notmatch 'Tailscale|Loopback'
    } |
    Sort-Object InterfaceMetric, SkipAsSource |
    Select-Object -First 1 -ExpandProperty IPAddress

$tail = Get-NetIPAddress -AddressFamily IPv4 -ErrorAction SilentlyContinue |
    Where-Object { $_.IPAddress -match '^100\.(6[4-9]|[7-9]\d|1[01]\d|12[0-7])\.' } |
    Select-Object -First 1 -ExpandProperty IPAddress

$env:IP_LOCAL = if ($lan) { $lan } else { '' }
$env:IP_TAILSCALE = if ($tail) { $tail } else { '' }

oh-my-posh init pwsh --config "$HOME\.poshthemes\omarchy-p10k-windows.omp.json" | Invoke-Expression
