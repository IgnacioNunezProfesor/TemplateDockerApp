Param(
    [string]$envFile = ".\env\dev.apachephp.env"    # Parámetro que permite especificar el archivo .env a usar
)
# Cargar variables de entorno desde el archivo
$envVars = @{}  # Crea un diccionario vacío para guardar las variables clave=valor

# Verifica si el archivo .env existe
if (-not (Test-Path $envFile)) {
    # Muestra error si no se encuentra el archivo
    Write-Error "Archivo de entorno '$envFile' no encontrado."
    # Sale del script con código de error
    exit 1
}

# Lee el archivo línea por línea y extrae las variables
Get-Content $envFile | ForEach-Object {
    # Busca líneas con formato clave=valor usando expresión regular
    if ($_ -match '^\s*([^=]+)=(.*)$') {
        # Guarda la clave y el valor en el diccionario
        $envVars[$matches[1]] = $matches[2]
    }
}

# Configurar variables a partir del diccionario cargado desde el archivo .env
$imageName = $envVars['IMAGE_NAME'] # Nombre de la imagen Docker que se va a usar 
$containerName = $envVars['CONTAINER_NAME'] # Nombre del contenedor que se va a crear o ejecutar 
$ip = $envVars['SERVER_IP'] # IP que se asignará al contenedor dentro de la red Docker

$moodleservername = $envVars['MOODLE_SERVER_NAME'] # Nombre del servidor virtual para Moodle (usado en Apache)
$servername = $envVars['SERVER_NAME'] # Nombre completo del servidor
$moodleserverport = $envVars['MOODLE_SERVER_PORT'] # Puerto en el que se ejecutará el servidor Moodle

$MOODLE_VOLUME_PATH = $envVars['MOODLE_VOLUME_PATH'] # Ruta local donde están los archivos fuente de Moodle
$volumePath = $envVars['VOLUME_PATH'] # Ruta local para otros archivos fuente del proyecto

$networkName = $envVars['NETWORK_NAME'] # Nombre de la red Docker donde se conectará el contenedor

# Eliminar contenedor si existe
if (docker ps -a --filter "name=^${containerName}$" --format "{{.Names}}" | Select-Object -First 1) {
    Write-Host "Eliminando contenedor existente: $containerName"    # Muestra mensaje si se encuentra un contenedor con ese nombre
    docker stop $containerName 2>$null  # Intenta detener el contenedor (ignora errores con 2>null)
    docker rm $containerName 2>$null    # Elimina el contenedor (ignora errores con 2>null)
}

# Ejecutar el contenedor Docker con todos los parámetros definidos
$dockerCmd = @(
    "docker run -d",    # Ejecuta el contenedor en segundo plano
    "--name ${containerName}",  # Asigna nombre al contenedor
    "-p ${moodleserverport}:80",   # Mapea el puerto del host al puerto 80 del contenedor
    "-v ${volumePath}:/var/www/localhost/htdocs",   # Monta volumen general del proyecto en Apache
    "-v ${MOODLE_VOLUME_PATH}:/var/www/${moodleservername}",    # Monta volumen específico de Moodle en su ruta correspondiente
    "-v .\logs\apachephp:/var/log/apache2",     # Monta carpeta local de logs en la ruta de logs de Apache
    "--env-file $envFile",      # Carga todas las variables de entorno desde el archivo .env
    "--hostname $containerName",    # Asigna nombre de host al contenedor
    "--network $networkName",   # Conecta el contenedor a la red Docker especificada
    "--ip $ip",     # Asigna IP fija dentro de la red Docker
    "--add-host ${servername}:${ip}",   # Asigna IP fija dentro de la red Docker
    "--add-host ${moodleservername}:${ip}",     # Añade entrada al /etc/hosts para el nombre del servidor Moodle
    $imageName      # Imagen Docker que se va a usar para crear el contenedor
) -join ' '     # Une todos los elementos en una sola cadena de texto

# Muestra el comando que se va a ejecutar
Write-Host "Ejecutando: $dockerCmd"
# Ejecuta el comando Docker
Invoke-Expression $dockerCmd