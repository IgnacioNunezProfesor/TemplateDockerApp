# Define parameters with default values
param(
    [string]$envFile = ".\env\dev.mysql.env"
)
$envVars = @{}

# Validar que el archivo de entorno exista
if (-not (Test-Path $envFile)) {
    Write-Error "Env file '$envFile' not found."
    exit 1
} 
# Leer y parsear el archivo de entorno, ignorando líneas vacías y comentarios
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^=]+)=(.*)$') {
        $envVars[$matches[1]] = $matches[2]
    }
}


# Configurar variables a partir del archivo de entorno

$containerName = $envVars['DB_CONTAINER_NAME']
# Las siguientes variables están comentadas porque no se usan directamente en este script
# pero se pasan al contenedor a través del archivo .env
#$dbName = $envVars['DB_NAME']
#$dbUSer = $envVars['DB_USER']
#$dbPass = $envVars['DB_PASS']
#$dbRootPass = $envVars['DB_ROOT_PASS']
#$dbName = $envVars['DB_NAME']
#$dbUSer = $envVars['DB_USER']
#$dbPass = $envVars['DB_PASS']
#$dbRootPass = $envVars['DB_ROOT_PASS']
$dbDataDir = $envVars['DB_DATADIR']
$dbLogDir = $envVars['DB_LOG_DIR']
$port = $envVars['DB_PORT'] 
$imageName = $envVars['DB_IMAGE_NAME']
$networkName = $envVars['DB_NETWORK_NAME']
$ip = $envVars["DB_IP"]



# Eliminar contenedor si existe para evitar conflictos
if (docker ps -a --filter "name=^${containerName}$" --format "{{.Names}}" | Select-Object -First 1) {
    Write-Host "Eliminando contenedor existente: $containerName"
    docker stop $containerName 2>$null # Detener contenedor si está corriendo
    docker rm $containerName 2>$null # Eliminar contenedor
}

# Construir y ejecutar comando docker
$dockerCmd = @(
    "docker run -d", # Ejecutar en segundo plano
    "--name $containerName", # Nombre del contenedor
    "-p ${port}:${port}", # Mapeo de puertos
    "-v .\mysql_data:$dbDataDir", # Volumen para datos de MySQL
    "-v .\logs\mysql:$dbLogDir", # Volumen para logs de MySQL
    "--env-file $envFile", # Variables de entorno desde archivo
    "--hostname $containerName", # Hostname interno
    "--network $networkName", # Red Docker personalizada
    "--ip $ip" # IP estática en la red
    $imageName # Imagen de Docker a usar
) -join ' '

Write-Host "Ejecutando: $dockerCmd"
Invoke-Expression $dockerCmd # Ejecutar el comando Docker