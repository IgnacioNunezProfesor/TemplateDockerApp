Param( # Parámetro de entrada del script
    [string]$envFile = ".\env\dev.apachephp.env" # Ruta del archivo .env
)
# Cargar variables de entorno desde el archivo 
$envVars = @{} # Diccionario donde se guardarán las variables


if (-not (Test-Path $envFile)) { # Comprueba si el archivo .env existe
    Write-Error "Archivo de entorno '$envFile' no encontrado." # Mensaje de error
    exit 1 # Finaliza el script
}

Get-Content $envFile | ForEach-Object { # Lee el archivo línea por línea
    if ($_ -match '^\s*([^=]+)=(.*)$') { # Detecta líneas con formato clave=valor
        $envVars[$matches[1]] = $matches[2] # Guarda la clave y el valor
    }
}

# Configurar variables 
$imageName = $envVars['IMAGE_NAME'] # Nombre de la imagen Docker
$containerName = $envVars['CONTAINER_NAME'] # Nombre del contenedor
$ip = $envVars['SERVER_IP'] # IP del contenedor

$moodleservername = $envVars['MOODLE_SERVER_NAME'] # Dominio del servidor Moodle
$servername = $envVars['SERVER_NAME'] # Nombre del servidor Apache
$moodleserverport = $envVars['MOODLE_SERVER_PORT'] # Puerto del servidor Moodle

$MOODLE_VOLUME_PATH = $envVars['MOODLE_VOLUME_PATH'] # Ruta del volumen de Moodle
$volumePath = $envVars['VOLUME_PATH'] # Ruta del volumen general

$networkName = $envVars['NETWORK_NAME'] # Nombre de la red Docker

# Eliminar contenedor si existe 
if (docker ps -a --filter "name=^${containerName}$" --format "{{.Names}}" | Select-Object -First 1) {
    Write-Host "Eliminando contenedor existente: $containerName" # Aviso
    docker stop $containerName 2>$null # Detiene el contenedor
    docker rm $containerName 2>$null # Lo elimina
}

# Ejecutar el contenedor Docker 
$dockerCmd = @(
    "docker run -d", # Ejecutar en segundo plano
    "--name ${containerName}", # Nombre del contenedor
    "-p ${moodleserverport}:80", # Mapeo de puertos
    "-v ${volumePath}:/var/www/localhost/htdocs", # Volumen del código
    "-v ${MOODLE_VOLUME_PATH}:/var/www/${moodleservername}", # Volumen de Moodle
    "-v .\logs\apachephp:/var/log/apache2", # Volumen de logs
    "--env-file $envFile", # Cargar variables de entorno
    "--hostname $containerName", # Hostname interno
    "--network $networkName", # Red Docker
    "--ip $ip", # IP fija
    "--add-host ${servername}:${ip}", # Entrada en /etc/hosts
    "--add-host ${moodleservername}:${ip}", # Entrada adicional
    $imageName # Imagen a ejecutar
) -join ' ' # Unir todo en una sola línea

Write-Host "Ejecutando: $dockerCmd" # Mostrar comando final
Invoke-Expression $dockerCmd # Ejecutar comando