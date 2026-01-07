# CrearRedDocker.ps1
# Script para crear una red en Docker usando PowerShell-
<#
.SYNOPSIS
    Crea una red en Docker con configuración personalizable.
.EXAMPLE
    .\create_network.ps1
    .\create_network.ps1 -NetworkName "MyNetwork" -Driver "bridge"
    .\create_network.ps1 -NetworkName "MyNetwork" -Subnet "192.168.0.0/16" -Gateway "192.168.0.1"
#>
# CrearRedDocker.ps1
# Script para crear una red en Docker usando PowerShell
# Facilita la creación de redes personalizadas para entornos de desarrollo

<#
.SYNOPSIS
    Crea una red en Docker con configuración personalizable.
    
.DESCRIPTION
    Este script automatiza la creación de redes Docker con opciones como
    nombre personalizado, driver, subred y gateway. Es útil para configurar
    redes aisladas para aplicaciones multi-contenedor.
    
.PARAMETER NetworkName
    Nombre de la red Docker a crear. Por defecto 'MoodleNet'.
    
.PARAMETER Driver
    Driver de red Docker (bridge, overlay, host, etc.). Por defecto 'bridge'.
    
.PARAMETER Subnet
    Subred en formato CIDR (ej: 172.25.0.0/16). Opcional.
    
.PARAMETER Gateway
    Dirección IP del gateway para la subred. Opcional.
    
.EXAMPLE
    .\create_network.ps1
    Crea red 'MoodleNet' con driver bridge
    
.EXAMPLE
    .\create_network.ps1 -NetworkName "MyNetwork" -Driver "bridge"
    Crea red personalizada 'MyNetwork'
    
.EXAMPLE
    .\create_network.ps1 -NetworkName "MyNetwork" -Subnet "192.168.0.0/16" -Gateway "192.168.0.1"
    Crea red con configuración de red específica
#>

# Definir parámetros con valores por defecto
param(
    [string]$NetworkName = "MoodleNet",   # Nombre por defecto para proyectos Moodle
    [string]$Driver = "bridge",           # Driver más común para redes locales
    [string]$Subnet = "172.25.0.0/16",    # Subred privada no conflictiva
    [string]$Gateway = "172.25.0.1"       # Gateway dentro de la subred
)

# Mostrar mensaje informativo al usuario
Write-Host "Creando red Docker: $NetworkName con driver $Driver..." -ForegroundColor Cyan

# Construir comando docker network create dinámicamente
$command = "docker network create --driver $Driver"  # Parte base del comando

# Agregar configuración de subred y gateway si ambos están especificados
# Ambos deben estar presentes para evitar configuración inconsistente
if ($Subnet -and $Gateway) {
    $command += " --subnet=$Subnet --gateway=$Gateway"
}

# Agregar nombre de la red al final del comando
$command += " $NetworkName"

# Ejecutar comando usando Invoke-Expression
# Esto ejecuta el string como si fuera tecleado en la consola
Invoke-Expression $command

# Verificar creación mostrando lista de redes disponibles
# Útil para confirmar que la red se creó correctamente
Write-Host "Redes disponibles:" -ForegroundColor Green
docker network ls # Mostrar todas las redes Docker
