# WinP10k Aurora

Tema azul y blanco para Oh My Posh, inspirado en Powerlevel10k y ajustado para PowerShell 7 y Windows Terminal. El prompt mantiene la línea de entrada a la izquierda, con puntas simétricas y la información secundaria distribuida a la derecha.

## Índice

- [Qué muestra](#qué-muestra)
- [Requisitos](#requisitos)
- [Instalar](#instalar)
  - [Opción A: clonar con Git](#opción-a-clonar-con-git)
  - [Opción B: descargar el ZIP](#opción-b-descargar-el-zip)
- [Asistente para configurar el perfil](#asistente-para-configurar-el-perfil)
  - [Prompt para usar con Codex](#prompt-para-usar-con-codex)
  - [Componentes y enlaces oficiales](#componentes-y-enlaces-oficiales)
  - [Qué es necesario y qué es opcional](#qué-es-necesario-y-qué-es-opcional)
- [Integración opcional con Proxmox y TOTP](#integración-opcional-con-proxmox-y-totp)
- [Seguridad y privacidad](#seguridad-y-privacidad)
- [Actualizar](#actualizar)
- [Desinstalar](#desinstalar)
- [Personalizar](#personalizar)
- [Preguntas frecuentes](#preguntas-frecuentes)
  - [Comprobar la versión de PowerShell](#cómo-compruebo-que-estoy-usando-powershell-7)
  - [El prompt no aparece o sigo viendo el tema anterior](#el-prompt-no-aparece-o-sigo-viendo-el-tema-anterior)
  - [Símbolos incorrectos](#veo-cuadrados-o-símbolos-incorrectos)
  - [IP LAN o Tailscale](#no-aparece-la-ip-lan-o-tailscale)
  - [Estado de Git](#no-veo-el-estado-de-git)
  - [Windows Terminal cambia de color o fuente](#por-qué-cambia-el-color-y-la-fuente-predeterminados-de-windows-terminal)
  - [Información del lado derecho](#se-oculta-la-información-del-lado-derecho)
  - [Permisos de administrador](#el-instalador-necesita-permisos-de-administrador)
  - [Problemas con WinGet](#winget-no-aparece-o-no-puede-instalar-una-aplicación)
  - [Problemas con SSH y el alias](#ssh-no-usa-el-alias-o-conecta-al-host-equivocado)
  - [Problemas con OTP](#ssh-conecta-pero-el-otp-falla)
  - [Problemas con Wake-on-LAN](#wake-on-lan-no-enciende-proxmox)
- [Créditos](#créditos)

## Qué muestra

- Último comando, ruta actual y estado de Git.
- Estado del comando anterior, duración y trabajos de PowerShell en segundo plano.
- Hora, contador de actualizaciones de winget, batería y uso de memoria.
- IP local y Tailscale cuando están disponibles.
- Colores semánticos brillantes: verde para éxito, rojo para error y azul/cian para información.

El perfil auxiliar consulta las direcciones IPv4 una vez al iniciar PowerShell. El tema oculta los datos de red que no estén disponibles.

## Requisitos

- Windows 10 u 11.
- PowerShell 7 o posterior (`pwsh`). El instalador no funciona en Windows PowerShell 5.1.
- `winget` (App Installer), requerido por el instalador. Si Oh My Posh no está instalado, el instalador lo instala con winget.
- Conexión a Internet durante la instalación de Oh My Posh y Meslo Nerd Font.
- Windows Terminal recomendado. El tema también funciona en otras terminales compatibles con PowerShell 7 y Oh My Posh.
- Git opcional: se necesita para mostrar información de repositorios Git.
- Tailscale opcional: su dirección solo aparece si el cliente está instalado y conectado.
- El asistente `setup.ps1` reúne la instalación del tema, herramientas de consola, módulos de PowerShell y la integración opcional de Proxmox.

El instalador configura Meslo Nerd Font. La fuente es necesaria para que los símbolos y flechas se vean correctamente.

## Instalar

Abre PowerShell 7. Comprueba que la ventana actual usa la versión correcta:

```powershell
$PSVersionTable.PSVersion
```

### Opción A: clonar con Git

```powershell
git clone https://github.com/ciprianotoor/winp10k-aurora.git
Set-Location .\winp10k-aurora
Set-ExecutionPolicy -Scope Process Bypass
.\install.ps1
```

### Opción B: descargar el ZIP

1. En GitHub, elige **Code → Download ZIP** y extrae el archivo.
2. Abre PowerShell 7 en la carpeta extraída.
3. Ejecuta:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\install.ps1
```

La política se cambia solo para esa ventana; no modifica la política permanente del equipo.

El instalador copia el tema y el perfil auxiliar a `$HOME\.poshthemes`, agrega un bloque identificado al perfil actual de PowerShell y guarda una copia del perfil anterior como `Microsoft.PowerShell_profile.ps1.winp10k-aurora.bak`. Si detecta un bloque anterior llamado **Omarchy P10k Windows**, también lo retira para evitar dos inicializaciones. Si detecta Windows Terminal, configura su esquema de color y fuente predeterminados. No requiere abrir PowerShell como administrador.

Cierra y vuelve a abrir Windows Terminal para cargar la fuente y el prompt.

## Asistente para configurar el perfil

Para instalar los componentes de forma guiada, ejecuta `setup.ps1` desde PowerShell 7:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\setup.ps1
```

El menú permite instalar el tema y la fuente, elegir herramientas de consola, elegir módulos de PowerShell, configurar Proxmox con TOTP y ajustar la privacidad del prompt. La opción 6 recorre todos los pasos y sigue preguntando antes de instalar cada herramienta o módulo.

El perfil administrado carga los módulos opcionales si están instalados, activa las sugerencias de PSReadLine, configura los atajos de PSFzf y zoxide, y agrega los alias `ll`, `la`, `cat` y `grep` cuando sus herramientas están disponibles. Las funciones personales que ya existen en el perfil se conservan.

### Prompt para usar con Codex

Si quieres que Codex te guíe o ejecute la configuración desde este repositorio, copia este prompt:

```text
Quiero configurar WinP10k Aurora en esta computadora usando este repositorio.

1. Lee README.md, setup.ps1, install.ps1 y los módulos del repositorio antes de cambiar nada. Resume qué hace cada opción del asistente y qué programas puede instalar.
2. Comprueba que la sesión actual sea PowerShell 7 y que winget esté disponible. Si no lo están, indícame cómo instalarlos desde sus fuentes oficiales.
3. Guíame por setup.ps1 y deja que yo elija qué programas, módulos e integraciones instalar. No instales aplicaciones opcionales sin mi elección.
4. Conserva mi perfil, la configuración existente de Windows Terminal y ~/.ssh/config. Usa las copias de seguridad que prepara el instalador y no reemplaces configuraciones existentes sin explicarme el cambio.
5. Para Proxmox, pregúntame solo por los datos de configuración que necesita el asistente, como alias SSH, host, MAC y puertos. No inventes valores ni modifiques el servidor Proxmox.
6. Nunca me pidas que pegue en el chat una semilla TOTP, código OTP, contraseña, clave privada SSH o códigos de recuperación. No los leas de archivos ni los guardes en scripts, perfiles, historial, argumentos o el repositorio. Si registro TOTP, deja que escriba la semilla directamente en el prompt interactivo de totp-cli.
7. No cambies la política de ejecución de forma permanente. Si hace falta, usa únicamente el ámbito Process para la ventana actual y explícame el efecto.
8. No te conectes a Proxmox, no envíes Wake-on-LAN ni ejecutes apagados para probar la instalación. Limítate a configurar el perfil y comprobar los archivos locales que modificaste.
9. Al terminar, dime qué quedó instalado y configurado, qué archivos cambiaste, qué pasos manuales me faltan y cómo deshacer los cambios. No incluyas secretos en el resumen.
```

### Componentes y enlaces oficiales

| Componente | Uso | Instalación o documentación |
| --- | --- | --- |
| PowerShell 7 | Shell compatible con el tema | [Instalar PowerShell en Windows](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-windows) |
| Oh My Posh | Motor del prompt | [Instalación en Windows](https://ohmyposh.dev/docs/installation/windows) |
| Meslo Nerd Font | Glifos del tema | [Fuentes para Oh My Posh](https://ohmyposh.dev/docs/installation/fonts) |
| Windows Terminal | Terminal recomendada | [Microsoft Store / Windows Terminal](https://aka.ms/terminal) |
| Git | Rama y estado de repositorios | [Git para Windows](https://git-scm.com/download/win) |
| fzf | Búsqueda interactiva usada por PSFzf | [Repositorio de fzf](https://github.com/junegunn/fzf) |
| ripgrep (`rg`) | Búsqueda rápida de texto | [Repositorio de ripgrep](https://github.com/BurntSushi/ripgrep) |
| bat | Visor de archivos con formato | [Repositorio de bat](https://github.com/sharkdp/bat) |
| zoxide | Navegación por historial de directorios | [Repositorio de zoxide](https://github.com/ajeetdsouza/zoxide) |
| GitHub CLI | Operaciones de GitHub desde la terminal | [Instalación de GitHub CLI](https://cli.github.com/) |
| Tailscale | Mostrar la IP Tailscale si está conectado | [Instalación de Tailscale](https://tailscale.com/download/windows) |
| Terminal-Icons | Iconos para archivos en PowerShell | [PowerShell Gallery](https://www.powershellgallery.com/packages/Terminal-Icons) |
| PSFzf | Atajos de fzf en PSReadLine | [PowerShell Gallery](https://www.powershellgallery.com/packages/PSFzf) |
| CompletionPredictor | Sugerencias predictivas; proyecto experimental | [Repositorio oficial](https://github.com/PowerShell/CompletionPredictor) |
| totp-cli | Generar códigos TOTP desde la consola | [Repositorio de totp-cli](https://github.com/yitsushi/totp-cli) |

El asistente instala aplicaciones con identificadores exactos de WinGet y módulos con `Install-Module -Scope CurrentUser`; no instala componentes en todo el equipo. Las herramientas opcionales se pueden omitir. Para PSFzf también necesitas fzf.

### Qué es necesario y qué es opcional

Para ejecutar `setup.ps1` o `install.ps1` necesitas **Windows 10 u 11, PowerShell 7 y WinGet**. PowerShell 7 se puede instalar con WinGet (`winget install --exact --id Microsoft.PowerShell --source winget`) o desde el [instalador oficial para Windows](https://learn.microsoft.com/powershell/scripting/install/installing-powershell-on-windows). WinGet forma parte de **App Installer**; si falta, instálalo desde [Microsoft Store](https://apps.microsoft.com/detail/9nblggh4nns1).

Para que aparezca el tema necesitas **Oh My Posh y Meslo Nerd Font**. La opción 1 de `setup.ps1` o `install.ps1` instala Oh My Posh con el ID `JanDeDobbeleer.OhMyPosh` y ejecuta `oh-my-posh font install meslo`. También puedes seguir las instrucciones oficiales de [Oh My Posh para Windows](https://ohmyposh.dev/docs/installation/windows) y [fuentes Nerd Font](https://ohmyposh.dev/docs/installation/fonts). **Windows Terminal es recomendado**, pero no indispensable: puedes usar otra terminal compatible con PowerShell 7 y fuentes Nerd Font.

Los demás programas y módulos son **opcionales** y habilitan funciones adicionales. El menú 2 ofrece aplicaciones WinGet por ID exacto; como alternativa, usa los instaladores o releases oficiales enlazados en la tabla. El menú 3 instala módulos de PowerShell solo para tu usuario. También puedes instalarlos manualmente:

```powershell
Install-Module -Name Terminal-Icons -Repository PSGallery -Scope CurrentUser
Install-Module -Name PSFzf -Repository PSGallery -Scope CurrentUser
Install-Module -Name CompletionPredictor -Repository PSGallery -Scope CurrentUser
```

| Función opcional | Programa o módulo | ID de WinGet o método |
| --- | --- | --- |
| Rama y estado Git | Git | `Git.Git` |
| Terminal recomendada | Windows Terminal | `Microsoft.WindowsTerminal` o Microsoft Store |
| Búsqueda interactiva / atajos PSFzf | fzf y PSFzf | `junegunn.fzf` + módulo `PSFzf` |
| Búsqueda de texto | ripgrep | `BurntSushi.ripgrep.MSVC` |
| Visor de archivos | bat | `sharkdp.bat` |
| Navegación de carpetas | zoxide | `ajeetdsouza.zoxide` |
| Comandos de GitHub | GitHub CLI | `GitHub.cli` |
| IP Tailscale en el prompt | Tailscale | `Tailscale.Tailscale` |
| OTP para el menú Proxmox | totp-cli | `yitsushi.totp-cli`; se ofrece al configurar Proxmox |

Cada aplicación de esa tabla también tiene un enlace a su proyecto o instalador oficial en la tabla anterior. Algunas aplicaciones, como Tailscale, pueden solicitar elevación durante su propio instalador. El perfil omite las funciones asociadas si no instalas sus dependencias.

## Integración opcional con Proxmox y TOTP

El asistente de Proxmox pregunta el alias SSH, host o IP, MAC, dirección broadcast, puertos y el nombre del token de `totp-cli`. Si el alias SSH no existe, agrega un bloque al inicio de `~/.ssh/config` y conserva una copia de seguridad del archivo anterior. Si el alias ya existe, no lo modifica. Comprueba que el alias sea correcto con `ssh proxmox` antes de usar el menú.

El módulo se instala en la carpeta de módulos de PowerShell del usuario. Escribe `proxmox` para abrir el menú: puede enviar Wake-on-LAN, abrir la interfaz web, conectar por SSH o pedir el apagado remoto. Antes de SSH, `totp-cli` solicita la contraseña de su almacén y el módulo copia el código OTP al portapapeles. Pégalo cuando SSH lo solicite. Al terminar SSH, el módulo limpia el portapapeles si el código sigue allí.

Para registrar el OTP, el asistente puede ejecutar `totp-cli add-token proxmox proxmox`. Escribe el secreto de configuración directamente en el prompt de `totp-cli`; no es el código de seis dígitos que cambia. No pegues el secreto en el asistente, en el perfil, en argumentos de comandos ni en este repositorio. El script no lee ni guarda ese secreto. Si el módulo PAM estándar de Google Authenticator se configuró con el archivo predeterminado, su formato guarda la clave en `~/.google_authenticator`; instalaciones personalizadas pueden usar otra ruta. Consulta la [documentación del formato](https://github.com/google/google-authenticator-libpam/blob/master/FILEFORMAT) y protege siempre el secreto.

La configuración de red del menú se guarda solo en `%LOCALAPPDATA%\WinP10kAurora\proxmox.json`; no contiene contraseña ni secreto TOTP. Los códigos OTP permanecen en el portapapeles mientras la sesión está abierta. Si vence el código antes de que SSH lo acepte, genera otro con `totp-cli generate proxmox proxmox` en una segunda ventana.

## Seguridad y privacidad

- Ejecuta el asistente como usuario normal. No necesita permisos de administrador para instalar el perfil, módulos de usuario o editar la configuración de Windows Terminal.
- El bypass de ejecución documentado tiene ámbito `Process`; se descarta al cerrar esa ventana y no cambia la política permanente.
- El instalador conserva una copia inicial del perfil y de `settings.json` de Windows Terminal antes de editarlos. El asistente hace una copia de `~/.ssh/config` antes de añadir un alias nuevo.
- No guardes contraseñas, claves privadas ni semillas TOTP en este repositorio. Usa [autenticación SSH por clave](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_keymanagement) cuando sea posible y deja que `totp-cli` gestione su almacén protegido con su propia contraseña.
- El prompt puede mostrar el último comando y las direcciones LAN/Tailscale. Usa la opción 5 del asistente para ocultar cualquiera de esos datos; esa preferencia se guarda localmente en `%LOCALAPPDATA%\WinP10kAurora\profile.json`.
- No escribas secretos como argumentos de comandos: PowerShell puede conservar la línea en el historial. El secreto TOTP debe introducirse directamente cuando `totp-cli` lo solicite.
- WinGet instala paquetes desde su fuente configurada y PowerShell Gallery instala módulos seleccionados por el usuario. Revisa los proyectos enlazados y sus licencias antes de instalar.

Antes de ejecutar `setup.ps1`, revisa su contenido y descárgalo desde el repositorio oficial del proyecto. Algunas aplicaciones opcionales pueden solicitar permisos o pasos propios durante la instalación.

## Actualizar

Si clonaste el repositorio, desde su carpeta ejecuta:

```powershell
git pull
.\install.ps1
```

Si lo instalaste desde un ZIP, descarga y extrae la versión nueva y vuelve a ejecutar `install.ps1`. El instalador reemplaza los archivos Aurora y actualiza su bloque marcado en el perfil.

Para actualizar las herramientas o el módulo de Proxmox, ejecuta `setup.ps1` y vuelve a elegir el componente correspondiente. El instalador conserva el alias SSH existente.

## Desinstalar

Desde la carpeta del repositorio, ejecuta:

```powershell
.\uninstall.ps1
```

Esto quita la inicialización marcada del perfil actual. Conserva los archivos Aurora, Oh My Posh, Meslo Nerd Font y el esquema de Windows Terminal. Para volver a instalar, ejecuta `install.ps1` otra vez.

El desinstalador conserva las aplicaciones, módulos opcionales, el alias SSH y la configuración local de Proxmox. Se mantienen para evitar borrar datos o accesos que el usuario ya esté utilizando.

## Personalizar

- Colores, segmentos y decoración: `themes/winp10k-aurora.omp.json`.
- Detección de IP y datos para el prompt: `profile/WinP10k-Aurora.ps1`.
- Esquema de Windows Terminal y pasos de instalación: `install.ps1`.

El instalador agrega una referencia independiente al perfil existente; no reemplaza sus funciones o ajustes personales.



## Preguntas frecuentes

### ¿Cómo compruebo que estoy usando PowerShell 7?

Ejecuta `$PSVersionTable.PSVersion`. La versión mayor debe ser 7 o superior. Windows Terminal es la aplicación de terminal; puede abrir distintas versiones de PowerShell. El instalador debe ejecutarse dentro de una sesión `pwsh`.

### El prompt no aparece o sigo viendo el tema anterior

Cierra y vuelve a abrir la terminal. Comprueba que el archivo exista y que el perfil actual incluya el bloque Aurora:

```powershell
Test-Path "$HOME\.poshthemes\winp10k-aurora.omp.json"
Select-String -Path $PROFILE -Pattern 'WinP10k Aurora'
```

Si tienes varias instalaciones de PowerShell, ejecuta el instalador desde la misma versión que usas en Windows Terminal.

### Veo cuadrados o símbolos incorrectos

Selecciona **MesloLGM Nerd Font** en la configuración de fuente de Windows Terminal y reinícialo. Puedes volver a instalar la fuente con:

```powershell
oh-my-posh font install meslo
```

### No aparece la IP LAN o Tailscale

La IP LAN requiere una dirección privada IPv4 activa. La IP Tailscale requiere que Tailscale esté conectado. Si una dirección no está disponible, Aurora oculta ese segmento.

### No veo el estado de Git

Instala Git y sitúate dentro de una carpeta que pertenezca a un repositorio. Fuera de un repositorio, ese segmento no muestra una rama.

### ¿Por qué cambia el color y la fuente predeterminados de Windows Terminal?

Cuando encuentra el archivo de configuración de Windows Terminal, el instalador establece **WinP10k Aurora** y Meslo Nerd Font como valores predeterminados. Puedes cambiar esos valores en la configuración de Windows Terminal; la instalación del prompt no depende de que Aurora sea el esquema predeterminado.

### ¿Se oculta la información del lado derecho?

En una ventana estrecha, Windows Terminal y Oh My Posh pueden ocultar segmentos secundarios para conservar espacio para el prompt. Amplía la ventana si faltan datos; la línea donde escribes permanece a la izquierda.

### ¿El instalador necesita permisos de administrador?

No. Ejecuta PowerShell 7 en tu cuenta normal. El instalador modifica tu perfil y la configuración de Windows Terminal del usuario actual.

### WinGet no aparece o no puede instalar una aplicación

Primero distingue si falta el comando o si WinGet se ejecuta pero falla al encontrar/instalar un paquete.

**`winget` no se reconoce:** WinGet se distribuye con **App Installer**. Instálalo o actualízalo desde Microsoft Store, cierra todas las ventanas de PowerShell y abre una nueva. Si esa edición de Windows no incluye Microsoft Store (por ejemplo, algunas instalaciones LTSC), abre la [página oficial de instalación/actualización de App Installer](https://learn.microsoft.com/windows/msix/app-installer/install-update-app-installer) y usa su descarga manual. No instales paquetes AppX de repositorios o páginas de terceros.

Comprueba:

```powershell
Get-Command winget
winget --version
```

Si App Installer ya está instalado, revisa en Windows **Configuración > Aplicaciones > Alias de ejecución de aplicaciones** que `winget.exe` esté habilitado. Comprueba también que `$env:LOCALAPPDATA\Microsoft\WindowsApps` figure en el `PATH` del usuario; después abre una ventana nueva. No descargues `winget.exe` desde sitios de terceros.

**WinGet abre, pero no encuentra el paquete o falla la fuente:** comprueba las fuentes y actualízalas:

```powershell
winget source list
winget source update
winget search --id yitsushi.totp-cli --exact --source winget
```

Busca siempre el ID exacto que muestra `setup.ps1`. Si el paquete aparece, prueba instalarlo de forma explícita para ver el error completo:

```powershell
winget install --exact --id yitsushi.totp-cli --source winget --accept-source-agreements --accept-package-agreements
```

Si WinGet informa que el paquete ya está instalado, pero el comando no aparece, abre una ventana nueva para actualizar `PATH` y verifica `Get-Command totp-cli`. Si persiste, consulta la página del paquete y comprueba dónde instaló el ejecutable. Como alternativa, instala la aplicación desde su fuente oficial; no descargues binarios de sitios no oficiales. Consulta la [guía oficial para solucionar problemas de WinGet](https://learn.microsoft.com/windows/package-manager/winget/troubleshooting) y la [documentación de instalación](https://learn.microsoft.com/windows/package-manager/winget/install). Algunas aplicaciones pueden requerir elevación propia.

### SSH no usa el alias o conecta al host equivocado

Comprueba primero que el cliente OpenSSH esté instalado y que el alias resuelva a los datos correctos. Estos comandos no inician una sesión SSH:

```powershell
Get-Command ssh
ssh -V
Test-Path "$HOME\.ssh\config"
ssh -G proxmox | Select-String '^(hostname|user|port) '
```

Si `ssh` no existe, instala **OpenSSH Client** desde **Configuración > Sistema > Características opcionales > Ver características** y abre una nueva terminal. No necesitas instalar el servidor OpenSSH en Windows para conectarte a Proxmox.

Verifica que `$HOME\.ssh\config` tenga un bloque como este, sustituyendo host, usuario y puerto por los valores reales:

```sshconfig
Host proxmox
    HostName 192.168.1.10
    User admin
    Port 22
```

El nombre después de `Host` es el alias que escribes (`ssh proxmox`); `HostName` es la IP o DNS de Proxmox. El asistente conserva un alias ya existente y no lo reemplaza: si hay uno antiguo o duplicado, edita el archivo manualmente y vuelve a ejecutar `ssh -G proxmox` para revisar la configuración efectiva.

Si el alias resuelve bien pero no conecta, comprueba que el host esté encendido y que el puerto SSH sea accesible:

```powershell
Test-NetConnection 192.168.1.10 -Port 22
ssh -vv proxmox
```

Un tiempo de espera suele indicar host apagado, IP incorrecta, ruta de red o puerto/firewall; `Connection refused` suele indicar que el host responde pero el servicio SSH no escucha en ese puerto. Si el error indica que cambió la identificación del host, verifica primero que la IP corresponde a tu Proxmox antes de corregir la entrada `known_hosts`; no elimines esa protección a ciegas. La configuración del cliente se explica en la [documentación de OpenSSH para Windows](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_config).

Si SSH conecta pero rechaza el acceso, confirma que `User` sea el usuario Linux de Proxmox y que la cuenta esté habilitada. `Permission denied` puede ser una contraseña Linux incorrecta, una clave SSH no aceptada o un OTP rechazado; mira el texto del prompt que muestra SSH. Esta integración solo genera/copia el OTP: no cambia la configuración PAM/Google Authenticator del servidor. Si el servidor dejó de mostrar el desafío OTP, revisa en Proxmox su configuración SSH/PAM y conserva una sesión administrativa abierta mientras corriges autenticación para evitar perder acceso.

### SSH conecta, pero el OTP falla

Comprueba que `totp-cli` esté disponible. Genera un código con el espacio y la cuenta que registraste en el asistente:

```powershell
Get-Command totp-cli
totp-cli generate proxmox proxmox
```

Usa el nombre de espacio y de cuenta que configuraste si no son `proxmox`. Si la cuenta aún no está registrada, añade el secreto TOTP en el almacén local con `totp-cli add-token <espacio> <cuenta>` y escribe el secreto solo cuando la aplicación lo solicite. No lo pongas como argumento, en un script, en el historial, ni en Git. `totp-cli` puede pedir la contraseña de su almacén.

El código cambia periódicamente. Sincroniza el reloj de Windows (**Configuración > Hora e idioma > Fecha y hora > Sincronizar ahora**), genera el código justo antes de conectarte y pégalo en el prompt OTP de SSH. La integración `proxmox` genera y copia el código al portapapeles cuando eliges conectar; pégalo con `Ctrl+V` cuando SSH lo solicite. Si el código vence, genera otro y usa el siguiente intervalo. Si la cuenta no existe o la contraseña del almacén falla, revisa el nombre de espacio/cuenta y vuelve a registrar el secreto desde la fuente que ya tienes en Google Authenticator. No compartas la semilla, el OTP ni códigos de recuperación.

Si la función `proxmox` no abre el menú esperado, ejecuta `Get-Command proxmox -All` para detectar si otro perfil o módulo tiene una función con el mismo nombre. Vuelve a ejecutar la opción 4 de `setup.ps1` para instalar o actualizar el módulo de este repositorio. Si el portapapeles no se pega con `Ctrl+V`, prueba pegar con clic derecho o usa `totp-cli generate` y escribe el código manualmente.

No compartas la semilla TOTP, códigos OTP, códigos de recuperación, contraseñas ni claves privadas al pedir ayuda. Para revisar el problema basta con compartir los mensajes de error una vez ocultos los datos del host y del usuario.

### Wake-on-LAN no enciende Proxmox

La opción 1 envía un paquete Wake-on-LAN al **servidor físico Proxmox** y luego espera respuesta en el puerto web configurado. No enciende directamente una VM ni puede encender un servidor si el equipo no admite Wake-on-LAN.

1. En BIOS/UEFI y en la configuración de la tarjeta de red, habilita Wake-on-LAN (Wake on PCI-E/LAN) y permite que la interfaz reciba energía cuando el equipo está apagado.
2. Confirma que la MAC configurada pertenece a la interfaz Ethernet conectada y que `BroadcastAddress` es la dirección broadcast de esa misma subred. Wake-on-LAN puede fallar por Wi-Fi, redes invitadas, VLAN, VPN o routers que bloquean broadcasts.
3. Ejecuta el menú de Proxmox y elige la opción 1. El mensaje de paquete enviado solo confirma el envío local; espera hasta cinco minutos a que responda la interfaz web. Si el servidor ya está encendido, el envío no lo apaga: usa la opción SSH.
4. Si el servidor responde pero una VM está apagada, entra a la interfaz web de Proxmox, selecciona la VM y pulsa **Start**. Para iniciar VMs automáticamente después del arranque del nodo, configura **Options > Start at boot** en cada VM, según corresponda.

Si el nodo está encendido pero el asistente informa que no responde, verifica `HostAddress`, `WebPort` y acceso con `Test-NetConnection <IP-Proxmox> -Port 8006`. El puerto web predeterminado es 8006, pero puedes haber configurado otro. La opción SSH puede funcionar aunque la comprobación del puerto web falle si el puerto web está filtrado o usa otro puerto.

## Créditos

Diseño original basado en el tema Powerlevel10k personalizado del usuario y adaptado a Oh My Posh. Oh My Posh y Meslo Nerd Font son proyectos de terceros y conservan sus propias licencias.
