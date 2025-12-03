# Cargar variables de entorno desde el archivo
$envFile = ".\env\dev.mysql.env"
$envVars = @{}

if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*([^=]+)=(.*)$') {
            $envVars[$matches[1]] = $matches[2]
        }
    }
}
else {
    Write-Error "Archivo $envFile no encontrado"
    exit 1
}

# Configurar variables
#$servername = $envVars['SERVER_NAME'] ?? 'moodle.mysql'
$containerName = $envVars['CONTAINER_NAME'] ?? 'moodle.mysql'
$portMapping = $envVars['PORT_MAPPING'] ?? '3306:3306'
$imageName = $envVars['IMAGE_NAME'] ?? 'mysql:dev'
$hostEntry = $envVars['HOST_ENTRY'] ?? 'moodle.mysql:127.0.0.1'

# Eliminar contenedor si existe
if (docker ps -a --filter "name=^${containerName}$" --format "{{.Names}}" | Select-Object -First 1) {
    Write-Host "Eliminando contenedor existente: $containerName"
    docker stop $containerName 2>$null
    docker rm $containerName 2>$null
}

# Construir y ejecutar comando docker
$dockerCmd = @(
    "docker run -d",
    "--name $containerName",
    "-p $portMapping",
    "-v mysql_data:/var/lib/mysql",
    "-v logs_mysql:/var/log/mysql",
    "--env-file $envFile",
    "--add-host=$hostEntry",
    "--hostname $containerName",
    $imageName
) -join ' '

Write-Host "Ejecutando: $dockerCmd"
Invoke-Expression $dockerCmd