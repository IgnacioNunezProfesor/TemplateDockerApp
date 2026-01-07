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
param(
    [string]$NetworkName = "MoodleNetwork", # Nombre de la red
    [string]$Driver = "bridge", # Driver de red (bridge, overlay, host, etc.)
    [string]$Subnet = "172.25.0.0/16", # Subred opcional
    [string]$Gateway = "172.25.0.1" # Gateway opcional
)

Write-Host "Creando red Docker: $NetworkName con driver $Driver..." -ForegroundColor Cyan # Mensaje informativo

# Construir comando dinámico 
$command = "docker network create --driver $Driver" # Comando base

if ($Subnet -and $Gateway) { # Si se especifican Subnet y Gateway
    $command += " --subnet=$Subnet --gateway=$Gateway" # Añade parámetros de red
}

$command += " $NetworkName" # Añade el nombre de la red

# Ejecutar comando 
Invoke-Expression $command # Lanza el comando en PowerShell

# Verificar creación 
Write-Host "Redes disponibles:" -ForegroundColor Green # Mensaje informativo
docker network ls # Muestra las redes Docker
