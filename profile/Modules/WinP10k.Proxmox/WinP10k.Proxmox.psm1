function Get-WinP10kProxmoxConfig {
    $configPath = Join-Path $env:LOCALAPPDATA 'WinP10kAurora\proxmox.json'
    if (-not (Test-Path -LiteralPath $configPath)) {
        throw "No existe la configuracion $configPath. Ejecuta setup.ps1 y configura Proxmox."
    }

    $config = Get-Content -Raw -LiteralPath $configPath | ConvertFrom-Json
    if ($config.SshAlias -notmatch '^[A-Za-z0-9._-]+$') {
        throw 'El alias SSH guardado no es valido.'
    }
    return $config
}

function Invoke-WinP10kProxmoxSSH {
    param(
        [Parameter(Mandatory)]$Config,
        [string]$RemoteCommand
    )

    if (-not (Get-Command totp-cli -ErrorAction SilentlyContinue)) {
        Write-Error 'No se encontro totp-cli. Ejecuta setup.ps1 para instalarlo.'
        return
    }

    $otpOutput = & totp-cli generate $Config.OtpNamespace $Config.OtpAccount
    if ($LASTEXITCODE -ne 0) {
        Write-Error 'No se pudo generar el codigo OTP.'
        return
    }

    $otp = [string]($otpOutput | Select-Object -Last 1)
    $otp = $otp.Trim()
    if ($otp -notmatch '^\d{6}$') {
        Write-Error 'totp-cli no devolvio un codigo de seis digitos.'
        return
    }

    Set-Clipboard -Value $otp
    Write-Host 'Codigo OTP copiado. Pegalo con Ctrl+V cuando SSH lo solicite.'
    try {
        if ($RemoteCommand) {
            ssh -t $Config.SshAlias $RemoteCommand
        } else {
            ssh $Config.SshAlias
        }
    }
    finally {
        try {
            if ((Get-Clipboard -Raw).Trim() -eq $otp) {
                Set-Clipboard -Value ''
            }
        } catch {
            # The connection remains usable if clipboard cleanup is unavailable.
        }
        $otp = $null
    }
}

function Test-WinP10kProxmoxWeb {
    param([Parameter(Mandatory)]$Config)
    Test-NetConnection -ComputerName $Config.HostAddress -Port $Config.WebPort `
        -InformationLevel Quiet -WarningAction SilentlyContinue
}

function Send-WinP10kWakePacket {
    param([Parameter(Mandatory)]$Config)

    $mac = $Config.MacAddress -replace '[:-]', ''
    if ($mac -notmatch '^[0-9A-Fa-f]{12}$') {
        throw 'La direccion MAC debe tener 12 digitos hexadecimales.'
    }

    [byte[]]$macBytes = for ($i = 0; $i -lt 12; $i += 2) {
        [Convert]::ToByte($mac.Substring($i, 2), 16)
    }
    [byte[]]$packet = [byte[]]::new(102)
    for ($i = 0; $i -lt 6; $i++) { $packet[$i] = 0xFF }
    for ($i = 6; $i -lt 102; $i++) { $packet[$i] = $macBytes[($i - 6) % 6] }

    $udp = [System.Net.Sockets.UdpClient]::new()
    try {
        $udp.EnableBroadcast = $true
        $udp.Connect($Config.BroadcastAddress, [int]$Config.WakePort)
        [void]$udp.Send($packet, $packet.Length)
    }
    finally {
        $udp.Dispose()
    }
}

function proxmox {
    $config = Get-WinP10kProxmoxConfig
    do {
        Clear-Host
        Write-Host '============================' -ForegroundColor Cyan
        Write-Host '   Administracion Proxmox' -ForegroundColor Cyan
        Write-Host '============================' -ForegroundColor Cyan
        Write-Host '1. Encender Proxmox por red'
        Write-Host '2. Abrir la interfaz web'
        Write-Host '3. Conectar por SSH con OTP'
        Write-Host '4. Apagar Proxmox por SSH'
        Write-Host '0. Salir'
        $choice = Read-Host 'Seleccione una opcion (0-4)'

        switch ($choice) {
            '1' {
                Send-WinP10kWakePacket -Config $config
                Write-Host 'Paquete Wake-on-LAN enviado. Esperando que Proxmox responda...'
                $ready = $false
                for ($i = 0; $i -lt 60; $i++) {
                    if (Test-WinP10kProxmoxWeb -Config $config) {
                        $ready = $true
                        break
                    }
                    Start-Sleep -Seconds 5
                }
                if ($ready) {
                    Write-Host 'Proxmox esta listo.' -ForegroundColor Green
                    if ((Read-Host 'Iniciar sesion SSH? (s/n)') -match '^[Ss]') {
                        Invoke-WinP10kProxmoxSSH -Config $config
                    }
                } else {
                    Write-Warning 'Proxmox no respondio dentro del tiempo esperado.'
                }
                Read-Host 'Presione Enter para continuar'
            }
            '2' {
                Start-Process "https://$($config.HostAddress):$($config.WebPort)"
            }
            '3' {
                Invoke-WinP10kProxmoxSSH -Config $config
                Read-Host 'Presione Enter para continuar'
            }
            '4' {
                Invoke-WinP10kProxmoxSSH -Config $config -RemoteCommand 'sudo shutdown -h now'
                Read-Host 'Presione Enter para continuar'
            }
            '0' { return }
            default {
                Write-Host 'Opcion invalida.' -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    } while ($true)
}

Export-ModuleMember -Function proxmox
