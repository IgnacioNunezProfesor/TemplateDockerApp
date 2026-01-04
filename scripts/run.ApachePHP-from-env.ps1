Param(
    [string]$envFile = ".\env\dev.apachephp.env"   # Ruta del archivo .env que contiene las variables del contenedor
)
# Carga variables de entorno desde el archivo
$envVars = @{}   # Hashtable donde se guardarán las variables clave=valor

# Comprobar si el archivo .env existe
if (-not (Test-Path $envFile)) {
    Write-Error "Archivo de entorno '$envFile' no encontrado."
    exit 1
}

# Leer el archivo .env línea por línea y extraer pares clave=valor
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^=]+)=(.*)$') {
        $envVars[$matches[1]] = $matches[2]   # Guardar variable en el hashtable
    }
}

# Configurar variables
$imageName = $envVars['IMAGE_NAME']                 # Nombre de la imagen Docker
$containerName = $envVars['CONTAINER_NAME']         # Nombre del contenedor
$ip = $envVars['SERVER_IP']                         # IP fija del contenedor
$serverport = $envVars['SERVER_PORT']               # Puerto expuesto
$volumepath = $envVars['VOLUME_PATH']               # Ruta local del proyecto
$foldername = $envVars['FOLDER_NAME']               # Ruta interna donde se monta el proyecto
$datavolume = $envVars['DATA_VOLUME']               # Ruta local de datos persistentes
$datafolder = $envVars['DATA_FOLDER']               # Ruta interna de datos persistentes

$phpinfovolumepath = $envVars['PHPINFO_VOLUME_PATH']   # Ruta local del phpinfo
$phpinfofoldername = $envVars['PHPINFO_FOLDER_NAME']   # Ruta interna del phpinfo

$apachelogpath = $envVars['APACHE_LOG_PATH']           # Ruta local donde se guardarán los logs de Apache

# Crear red Docker si no existe y si se proporcionaron todos los parámetros necesarios
if (
        $envVars['NETWORK_NAME'] -and `
        $envVars['NETWORK_SUBNET'] -and `
        $envVars['NETWORK_SUBNET_GATEWAY'] -and `
        $envVars['SERVER_IP'] -and `
        -not (docker network ls --filter "name=^${envVars['NETWORK_NAME]}$" --format "{{.Name}}")
    ) {

        $networkName = $envVars['NETWORK_NAME']                 # Nombre de la red
        $networksubnet = $envVars['NETWORK_SUBNET']             # Subred de la red
        $networksubnetgateway = $envVars['NETWORK_SUBNET_GATEWAY'] # Gateway de la red
        $networkDriver = $envVars['NETWORK_DRIVER']             # Driver de red
        
        Write-Host "Creando red: $networkName"
        docker network create $networkName --driver=$networkDriver --subnet=$networksubnet --gateway=$networksubnetgateway
    } else {
        Write-Warning "La red Docker ya existe o no se proporcionaron todos los parámetros necesarios."
    }

# Si el contenedor ya existe, detenerlo y eliminarlo
if (docker ps -a --filter "name=^${containerName}$" --format "{{.Names}}" | Select-Object -First 1) {
    Write-Host "Eliminando contenedor existente: $containerName"
    docker stop $containerName 2>$null
    docker rm $containerName 2>$null
}

# Limpia contenido de la carpeta de logs de Apache si existe
if (Test-Path $apachelogpath) {
    Write-Host "Limpiando contenido de: $apachelogpath"
    Remove-Item "$apachelogpath\*" -Force -Recurse   # Borrar logs antiguos
}

# Copiar archivo de configuración de 
#$ConfigSrc = ".\docker\http\moodle\config-dist.php"
#$ConfigDest = ".\moodle_src\config.php"

#if (Test-Path $ConfigSrc) {
#    Write-Host "Copiando configuración de : $ConfigSrc -> $ConfigDest"
#    Copy-Item -Path $ConfigSrc -Destination $ConfigDest -Force
#} else {
#    Write-Warning "Archivo de configuración no encontrado: $ConfigSrc"
#}

# Ejecutar el contenedor Docker
$dockerCmd = @(
    "docker run -d",                                 # Ejecutar en segundo plano
    "--name ${containerName}",                       # Nombre del contenedor
    "-p ${serverport}:80",                           # Mapear puerto del host al contenedor
    "-v ${phpinfovolumepath}:${phpinfofoldername}",  # Montar carpeta phpinfo
    "-v ${volumepath}:${foldername}",                # Montar carpeta del proyecto
    "-v ${datavolume}:${datafolder}",                # Montar carpeta de datos persistentes
    "-v ${apachelogpath}:/var/log/apache2",          # Montar carpeta de logs de Apache
    "--env-file $envFile",                           # Cargar variables de entorno dentro del contenedor
    "--hostname $containerName",                     # Asignar hostname al contenedor
    "--network $networkName",                        # Conectar a la red Docker
    "--ip $ip",                                      # Asignar IP fija
    $imageName                                       # Imagen a ejecutar
) -join ' '

Write-Host "Ejecutando: $dockerCmd"
Invoke-Expression $dockerCmd   # Ejecutar comando final
