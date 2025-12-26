# Define parameters with default values
param(
    [string]$envFile = ".\env\dev.mysql.env"
)
$envVars = @{}

if (-not (Test-Path $envFile)) {
    Write-Error "Env file '$envFile' not found."
    exit 1
} 
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^=]+)=(.*)$') {
        $envVars[$matches[1]] = $matches[2]
    }
}

$containerName = $envVars['DB_CONTAINER_NAME']

$dbDataDir = $envVars['DB_DATADIR']
$dbLogDir = $envVars['DB_LOG_DIR']
$port = $envVars['DB_PORT'] 
$imageName = $envVars['DB_IMAGE_NAME']
$networkName = $envVars['DB_NETWORK_NAME']
$ip = $envVars["DB_IP"]

if ($envVars['DB_NETWORK_NAME'] -and $envVars['DB_NETWORK_SUBNET'] -and $envVars['DB_NETWORK_SUBNET_GATEWAY'] ) {
        $networkName = $envVars['DB_NETWORK_NAME']
        $networksubnet = $envVars['DB_NETWORK_SUBNET']
        $networksubnetgateway = $envVars['DB_NETWORK_SUBNET_GATEWAY']
        $networkdriver = $envVars['DB_NETWORK_DRIVER']

        Write-Host "Creando red: $networkName"
        .\scripts\create_network.ps1 -networkName $networkName -subnet $networksubnet -gateway $networksubnetgateway -driver $networkDriver    
}else{
        Write-Warning "La red Docker ya existe o no se proporcionaron todos los parámetros necesarios."
    }

# Eliminar contenedor si existe
if (docker ps -a --filter "name=^${containerName}$" --format "{{.Names}}" | Select-Object -First 1) {
    Write-Host "Eliminando contenedor existente: $containerName"
    docker stop $containerName 2>$null
    docker rm $containerName 2>$null
}

# Eliminar directorios de datos y logs si existen
if (Test-Path $dbDataDir) {
    Write-Host "Eliminando directorio de datos: $dbDataDir"
    Remove-Item -Path $dbDataDir -Recurse -Force
}

if (Test-Path $dbLogDir) {
    Write-Host "Eliminando directorio de logs: $dbLogDir"
    Remove-Item -Path $dbLogDir -Recurse -Force
}

# Construir y ejecutar comando docker
$dockerCmd = @(
    "docker run -d",
    "--name $containerName",
    "-p ${port}:${port}",
    "-v .\mysql_data:$dbDataDir",
    "-v .\logs\mysql:$dbLogDir",
    "--env-file $envFile",
    "--hostname $containerName",
    "--network $networkName",
    "--ip $ip"
    $imageName
) -join ' '

Write-Host "Ejecutando: $dockerCmd"
Invoke-Expression $dockerCmd