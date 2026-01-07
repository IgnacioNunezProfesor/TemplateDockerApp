# Define parámetros de entrada del script con valores por defecto
param(
    # Archivo de variables de entorno
    [string]$envFile = ".\env\dev.apachephp.env"
)

# Hashtable para almacenar las variables de entorno
# Cargadas desde el archivo especificado
$envVars = @{}

# Comprueba que el archivo de entorno exista
if (-not (Test-Path $envFile)) {
    # Si no existe, muestra un error y termina la ejecución
    Write-Error "Archivo de entorno '$envFile' no encontrado."
    exit 1
}

# Lee el archivo de entorno línea por línea y almacena clave=valor en la hashtable
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^=]+)=(.*)$') {
        $envVars[$matches[1]] = $matches[2]
    }
}

# Configurar variables locales desde la hashtable
$imageName = $envVars['IMAGE_NAME']               # Nombre de la imagen Docker
$containerName = $envVars['CONTAINER_NAME']      # Nombre del contenedor
$ip = $envVars['SERVER_IP']                      # IP del contenedor

$moodleservername = $envVars['MOODLE_SERVER_NAME']  # Nombre del servidor Moodle
$servername = $envVars['SERVER_NAME']               # Nombre del servidor Apache
$moodleserverport = $envVars['MOODLE_SERVER_PORT']  # Puerto del servidor Moodle

$MOODLE_VOLUME_PATH = $envVars['MOODLE_VOLUME_PATH']  # Ruta local del código de Moodle
$volumePath = $envVars['VOLUME_PATH']                 # Ruta local del servidor raíz
$networkName = $envVars['NETWORK_NAME']              # Nombre de la red Docker

# Crear la red Docker si no existe
if (
        $envVars['NETWORK_NAME'] -and `
        $envVars['NETWORK_SUBNET'] -and `
        $envVars['NETWORK_SUBNET_GATEWAY'] -and `
        $envVars['IP'] -and `
        -not (docker network ls --filter "name=^${envVars['NETWORK_NAME]}$" --format "{{.Name}}")
    ) {
        $networkName = $envVars['NETWORK_NAME']
        
        # Mensaje indicando creación de red
        Write-Host "Creando red: $networkName"

        # Crear la red con la subred y gateway definidos
        docker network create $networkName --subnet=$($envVars['NETWORK_SUBNET']) --gateway=$($envVars['NETWORK_SUBNET_GATEWAY'])
    }

# Eliminar contenedor si ya existe
if (docker ps -a --filter "name=^${containerName}$" --format "{{.Names}}" | Select-Object -First 1) {
    # Mensaje indicando eliminación del contenedor existente
    Write-Host "Eliminando contenedor existente: $containerName"

    # Detener y eliminar contenedor
    docker stop $containerName 2>$null
    docker rm $containerName 2>$null
}

# Construir el comando Docker para ejecutar el contenedor
$dockerCmd = @(
    "docker run -d",                                             # Ejecutar en segundo plano
    "--name ${containerName}",                                    # Nombre del contenedor
    "-p ${moodleserverport}:80",                                  # Mapear puerto del host al contenedor
    "-v ${volumePath}:/var/www/localhost/htdocs",                 # Montar volumen para el servidor raíz
    "-v ${MOODLE_VOLUME_PATH}:/var/www/${moodleservername}",      # Montar volumen para Moodle
    "-v .\logs\apachephp:/var/log/apache2",                       # Montar carpeta de logs
    "--env-file $envFile",                                        # Archivo de variables de entorno
    "--hostname $containerName",                                   # Nombre del host del contenedor
    "--network $networkName",                                     # Red Docker a usar
    "--ip $ip",                                                    # IP fija del contenedor
    "--add-host ${servername}:${ip}",                              # Añadir entrada en /etc/hosts para Apache
    "--add-host ${moodleservername}:${ip}",                        # Añadir entrada en /etc/hosts para Moodle
    $imageName                                                     # Imagen Docker a usar
) -join ' '

# Mostrar en pantalla el comando que se va a ejecutar
Write-Host "Ejecutando: $dockerCmd"

# Ejecutar el contenedor Docker
Invoke-Expression $dockerCmd
