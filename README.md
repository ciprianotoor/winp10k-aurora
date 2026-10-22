# WinP10k Aurora

Tema de Oh My Posh para PowerShell y Windows Terminal, inspirado en la estructura de Powerlevel10k y adaptado a una paleta azul y blanca.

Incluye prompt de dos líneas con entrada siempre a la izquierda, puntas simétricas, estado de Git y del último comando, duración, hora, batería, memoria, IP LAN y Tailscale. El perfil auxiliar obtiene todas las direcciones IPv4 con una sola consulta y actualiza las variables que muestra el tema.

## Requisitos

- Windows 10/11
- PowerShell 7 (pwsh)
- Windows Terminal recomendado
- Git y una fuente Nerd Font para mostrar los iconos correctamente

## Instalación

Desde PowerShell 7, en una ventana normal (sin administrador):

    Set-ExecutionPolicy -Scope Process Bypass
    .\install.ps1

El instalador instala Oh My Posh si falta, instala Meslo Nerd Font, copia el tema, agrega la inicialización al perfil de PowerShell 7 y configura el esquema azul en Windows Terminal cuando encuentra sus ajustes. Hace una copia del perfil antes de editarlo. Cierra y vuelve a abrir Windows Terminal al terminar.

Para actualizar, ejecuta de nuevo el instalador; también actualizará el perfil auxiliar de red y prompt. Para desinstalar la inicialización, ejecuta .\uninstall.ps1; el tema instalado se conserva para poder restaurarlo o quitarlo manualmente.

## Personalización

Edita themes/winp10k-aurora.omp.json. La lógica reutilizable del prompt y la detección LAN/Tailscale está en profile/WinP10k-Aurora.ps1. El perfil agregado es independiente: no reemplaza el perfil personal ni sus funciones de shell o Proxmox.

## Desarrollo

Los cambios al tema se copian al destino %USERPROFILE%\\.poshthemes\\winp10k-aurora.omp.json. Valida JSON con ConvertFrom-Json y revisa la representación en una sesión de PowerShell 7 antes de publicar cambios.

## Créditos

Diseño original basado en el tema personalizado de Powerlevel10k del usuario; configuración de prompt implementada para Oh My Posh. Oh My Posh y Meslo Nerd Font son proyectos de terceros con sus propias licencias.

