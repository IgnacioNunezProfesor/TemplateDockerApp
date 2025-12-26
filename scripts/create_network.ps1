# CrearRedDocker.ps1
# Script para crear una red en Docker usando PowerShell-
<#
.SYNOPSIS
    # Breve descripción del propósito del script
    Crea una red en Docker con configuración personalizable.
.EXAMPLE
    # Ejecución simple con valores por defecto
    .\create_network.ps1
    # Ejemplo con nombre y driver personalizado
    .\create_network.ps1 -NetworkName "MyNetwork" -Driver "bridge"
    # Ejemplo con red personalizada
    .\create_network.ps1 -NetworkName "MyNetwork" -Subnet "192.168.0.0/16" -Gateway "192.168.0.1"
#>

# Parámetros que se pueden personalizar al ejecutar el script
param(
    [string]$NetworkName = "MoodleNetwork",   # # Nombre de la red Docker que se va a crear
    [string]$Driver = "bridge",               # Tipo de driver de red (bridge, overlay, host, etc.)
    [string]$Subnet = "172.25.0.0/16",        # Subred IP que se asignará a la red
    [string]$Gateway = "172.25.0.1"           # Dirección IP del gateway dentro de la red
)

# Muestra un mensaje indicando que se va a crear la red con los parámetros definidos
Write-Host "Creando red Docker: $NetworkName con driver $Driver..." -ForegroundColor Cyan

# Construir comando dinámico para crear la red Docker
$command = "docker network create --driver $Driver"     # Comienza el comando con el driver especificado

# Si se han definido Subnet y Gateway, se añaden al comando
if ($Subnet -and $Gateway) {
    $command += " --subnet=$Subnet --gateway=$Gateway"  # Añade configuración de red personalizada si está disponible
}

# Añade el nombre de la red al final del comando
$command += " $NetworkName"

# Ejecuta el comando construido
Invoke-Expression $command      # Interpreta y ejecuta la cadena como comando real

# Verifica que la red se ha creado mostrando todas las redes disponibles
Write-Host "Redes disponibles:" -ForegroundColor Green  # Muestra mensaje en verde
docker network ls   # Lista todas las redes Docker existentes
