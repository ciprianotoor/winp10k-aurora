# WinP10k Aurora

Tema azul y blanco para Oh My Posh, inspirado en Powerlevel10k y ajustado para PowerShell 7 y Windows Terminal. El prompt mantiene la línea de entrada a la izquierda, con puntas simétricas y la información secundaria distribuida a la derecha.

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

## Actualizar

Si clonaste el repositorio, desde su carpeta ejecuta:

```powershell
git pull
.\install.ps1
```

Si lo instalaste desde un ZIP, descarga y extrae la versión nueva y vuelve a ejecutar `install.ps1`. El instalador reemplaza los archivos Aurora y actualiza su bloque marcado en el perfil.

## Desinstalar

Desde la carpeta del repositorio, ejecuta:

```powershell
.\uninstall.ps1
```

Esto quita la inicialización marcada del perfil actual. Conserva los archivos Aurora, Oh My Posh, Meslo Nerd Font y el esquema de Windows Terminal. Para volver a instalar, ejecuta `install.ps1` otra vez.

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

## Créditos

Diseño original basado en el tema Powerlevel10k personalizado del usuario y adaptado a Oh My Posh. Oh My Posh y Meslo Nerd Font son proyectos de terceros y conservan sus propias licencias.
