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

# Parámetros de entrada del script con valores por defecto
param(
    # Nombre de la red Docker
    [string]$NetworkName = "MoodleNet",

    # Driver de red (puede ser bridge, overlay, host, etc.)
    [string]$Driver = "bridge",

    # Subred opcional para la red Docker
    [string]$Subnet = "172.25.0.0/16",

    # Gateway opcional para la red Docker
    [string]$Gateway = "172.25.0.1"
)

# Muestra un mensaje indicando el inicio de la creación de la red
Write-Host "Creando red Docker: $NetworkName con driver $Driver..." -ForegroundColor Cyan

# Construir el comando de Docker de forma dinámica
$command = "docker network create --driver $Driver"

# Si se especifican Subnet y Gateway, se añaden al comando
if ($Subnet -and $Gateway) {
    $command += " --subnet=$Subnet --gateway=$Gateway"
}

# Añade el nombre de la red al comando
$command += " $NetworkName"

# Ejecuta el comando Docker para crear la red
Invoke-Expression $command

# Verifica la creación mostrando todas las redes disponibles
Write-Host "Redes disponibles:" -ForegroundColor Green
docker network ls
