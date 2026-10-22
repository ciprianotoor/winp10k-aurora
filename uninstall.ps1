[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
if ($PSVersionTable.PSVersion.Major -lt 7) {
    throw 'Ejecuta este script desde PowerShell 7 (pwsh).'
}
$managedBlocks = @(
    [PSCustomObject]@{ Start = '# >>> WinP10k Aurora >>>'; End = '# <<< WinP10k Aurora <<<' }
    [PSCustomObject]@{ Start = '# >>> Omarchy P10k Windows >>>'; End = '# <<< Omarchy P10k Windows <<<' }
)
if (Test-Path -LiteralPath $PROFILE) {
    $content = Get-Content -Raw -LiteralPath $PROFILE
    $updated = $content
    foreach ($managedBlock in $managedBlocks) {
        $pattern = '(?s)' + [regex]::Escape($managedBlock.Start) + '.*?' + [regex]::Escape($managedBlock.End)
        $updated = [regex]::Replace($updated, $pattern, '')
    }
    $updated = $updated.Trim()
    Set-Content -LiteralPath $PROFILE -Value $updated -Encoding utf8
    Write-Host "Se quitó la inicialización del tema del perfil $PROFILE"
}
Write-Host 'El archivo del tema y la configuración de Windows Terminal se conservaron.'

