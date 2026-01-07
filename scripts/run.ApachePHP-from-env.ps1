# Definir parámetro con valor por defecto para archivo de entorno
Param(
    [string]$envFile = ".\env\dev.apachephp.env"
)
# Cargar variables de entorno desde el archivo especificado
$envVars = @{}

# Validar existencia del archivo de entorno
if (-not (Test-Path $envFile)) {
    Write-Error "Archivo de entorno '$envFile' no encontrado."
    exit 1
}
# Parsear archivo de entorno, línea por línea
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^=]+)=(.*)$') {
        $envVars[$matches[1]] = $matches[2]
    }
}

# Configurar variables extraídas del archivo de entorno
$imageName = $envVars['IMAGE_NAME']
$containerName = $envVars['CONTAINER_NAME'] 
$ip = $envVars['SERVER_IP']
$serverport = $envVars['SERVER_PORT']
$volumepath = $envVars['VOLUME_PATH']
$foldername = $envVars['FOLDER_NAME']
$datavolume = $envVars['DATA_VOLUME']
$datafolder = $envVars['DATA_FOLDER']

$phpinfovolumepath = $envVars['PHPINFO_VOLUME_PATH']
$phpinfofoldername = $envVars['PHPINFO_FOLDER_NAME']

$apachelogpath = $envVars['APACHE_LOG_PATH']

# Crear red Docker si no existe y se proporcionan todos los parámetros necesarios
if (
        $envVars['NETWORK_NAME'] -and ` # Verificar que exista nombre de red
        $envVars['NETWORK_SUBNET'] -and ` # Verificar que exista subred
        $envVars['NETWORK_SUBNET_GATEWAY'] -and `  # Verificar que exista gateway
        $envVars['SERVER_IP'] -and `  # Verificar que exista IP del servidor
        -not (docker network ls --filter "name=^${envVars['NETWORK_NAME]}$" --format "{{.Name}}")  # Verificar que la red no exista
    ) {
        $networkName = $envVars['NETWORK_NAME']
        $networksubnet = $envVars['NETWORK_SUBNET']
        $networksubnetgateway = $envVars['NETWORK_SUBNET_GATEWAY']
        $networkDriver = $envVars['NETWORK_DRIVER']
        
        Write-Host "Creando red: $networkName"
        docker network create $networkName --driver=$networkDriver --subnet=$networksubnet --gateway=$networksubnetgateway
    }else{
        Write-Warning "La red Docker ya existe o no se proporcionaron todos los parámetros necesarios."
    }

# Eliminar contenedor existente si hay uno con el mismo nombre
if (docker ps -a --filter "name=^${containerName}$" --format "{{.Names}}" | Select-Object -First 1) {
    Write-Host "Eliminando contenedor existente: $containerName"
    docker stop $containerName 2>$null
    docker rm $containerName 2>$null
}

# Limpiar contenido de la carpeta de logs de Apache si existe
# Esto previene que los logs crezcan demasiado entre ejecuciones
if (Test-Path $apachelogpath) {
    Write-Host "Limpiando contenido de: $apachelogpath"
    Remove-Item "$apachelogpath\*" -Force -Recurse
}

# Sección comentada para copiar configuración de Moodle
# (Parece ser una funcionalidad planeada pero no implementada aún)
#$ConfigSrc = ".\docker\http\moodle\config-dist.php"
#$ConfigDest = ".\moodle_src\config.php"

#if (Test-Path $ConfigSrc) {
#    Write-Host "Copiando configuración de : $ConfigSrc -> $ConfigDest"
#    Copy-Item -Path $ConfigSrc -Destination $ConfigDest -Force
#} else {
#    Write-Warning "Archivo de configuración no encontrado: $ConfigSrc"
#}

# Ejecutar el contenedor Docker con todas las configuraciones
$dockerCmd = @(
    "docker run -d",  # Ejecutar en modo detached
    "--name ${containerName}",  # Nombre del contenedor
    "-p ${serverport}:80", # Mapear puerto del host al puerto 80 del contenedor
    "-v ${phpinfovolumepath}:${phpinfofoldername}", # Volumen para archivos phpinfo
    "-v ${volumepath}:${foldername}", # Volumen para código fuente de la aplicación
    "-v ${datavolume}:${datafolder}", # Volumen para datos de la aplicación
    "-v ${apachelogpath}:/var/log/apache2", # Volumen para logs de Apache
    "--env-file $envFile", # Archivo con variables de entorno
    "--hostname $containerName",  # Hostname interno
    "--network $networkName", # Conectar a red personalizada
    "--ip $ip" # Asignar IP estática
    $imageName # Imagen de Docker a usar
) -join ' '

Write-Host "Ejecutando: $dockerCmd"
Invoke-Expression $dockerCmd # Ejecutar el comando construido