Param(
    [string]$envFile = ".\env\dev.apachephp.env"
)
# Cargar variables de entorno desde el archivo
$envVars = @{}

if (-not (Test-Path $envFile)) {
    Write-Error "Archivo de entorno '$envFile' no encontrado."
    exit 1
}
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^=]+)=(.*)$') {
        $envVars[$matches[1]] = $matches[2]
    }
}

# Configurar variables
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

if (
        $envVars['NETWORK_NAME'] -and `
        $envVars['NETWORK_SUBNET'] -and `
        $envVars['NETWORK_SUBNET_GATEWAY'] -and `
        $envVars['SERVER_IP'] -and `
        -not (docker network ls --filter "name=^${envVars['NETWORK_NAME]}$" --format "{{.Name}}")
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


if (docker ps -a --filter "name=^${containerName}$" --format "{{.Names}}" | Select-Object -First 1) {
    Write-Host "Eliminando contenedor existente: $containerName"
    docker stop $containerName 2>$null
    docker rm $containerName 2>$null
}

# Limpiar contenido de la carpeta de logs de Apache si existe
if (Test-Path $apachelogpath) {
    Write-Host "Limpiando contenido de: $apachelogpath"
    Remove-Item "$apachelogpath\*" -Force -Recurse
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
    "docker run -d",
    "--name ${containerName}",
    "-p ${serverport}:80",
    "-v ${phpinfovolumepath}:${phpinfofoldername}",
    "-v ${volumepath}:${foldername}",
    "-v ${datavolume}:${datafolder}",
    "-v ${apachelogpath}:/var/log/apache2",
    "--env-file $envFile",
    "--hostname $containerName",
    "--network $networkName",
    "--ip $ip"
    $imageName
) -join ' '

Write-Host "Ejecutando: $dockerCmd"
Invoke-Expression $dockerCmd