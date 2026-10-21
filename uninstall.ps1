[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw 'Ejecuta este script desde PowerShell 7 (pwsh).'
}
$start = '# >>> Omarchy P10k Windows >>>'
$end = '# <<< Omarchy P10k Windows <<<'
if (Test-Path -LiteralPath $PROFILE) {
    $content = Get-Content -Raw -LiteralPath $PROFILE
    $pattern = '(?s)' + [regex]::Escape($start) + '.*?' + [regex]::Escape($end)
    $updated = [regex]::Replace($content, $pattern, '').Trim()
    Set-Content -LiteralPath $PROFILE -Value $updated -Encoding utf8
    Write-Host "Se quitó la inicialización del tema del perfil $PROFILE"
}
Write-Host 'El archivo del tema y la configuración de Windows Terminal se conservaron.'
