# CrearRedDocker.ps1
# Script para crear una red en Docker usando PowerShell

<#
.SYNOPSIS
    Crea una red en Docker con configuración personalizable.

.EXAMPLE
    .\create_network.ps1
    .\create_network.ps1 -NetworkName "MyNetwork" -Driver "bridge"
    .\create_network.ps1 -NetworkName "MyNetwork" -Subnet "192.168.0.0/16" -Gateway "192.168.0.1"
#>

# Parámetros configurables del script con valores por defecto
param(
    [string]$NetworkName = "MoodleNet",   # Nombre de la red Docker a crear
    [string]$Driver = "bridge",           # Driver de red (bridge, overlay, host, etc.)
    [string]$Subnet = "172.25.0.0/16",    # Subred opcional para la red
    [string]$Gateway = "172.25.0.1"       # Gateway opcional para la red
)

# Muestra mensaje informativo
Write-Host "Creando red Docker: $NetworkName con driver $Driver..." -ForegroundColor Cyan

# Construye el comando base para crear la red
$command = "docker network create --driver $Driver"

# Si se especifican Subnet y Gateway, añadirlos al comando
if ($Subnet -and $Gateway) {
    $command += " --subnet=$Subnet --gateway=$Gateway"
}

# Añade el nombre de la red al comando final
$command += " $NetworkName"

# Ejecuta el comando construido dinámicamente
Invoke-Expression $command

# Muestra las redes existentes para verificar la creación
Write-Host "Redes disponibles:" -ForegroundColor Green
docker network ls

