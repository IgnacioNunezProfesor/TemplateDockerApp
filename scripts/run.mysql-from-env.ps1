# Define parameters with default values
param(
    [string]$envFile = ".\env\dev.mysql.env"   # Archivo .env desde el que se cargarán las variables
)

$envVars = @{}   # Hashtable donde se almacenarán las variables clave=valor

# Comprobar si el archivo .env existe
if (-not (Test-Path $envFile)) {
    Write-Error "Env file '$envFile' not found."
    exit 1
} 

# Lee archivo .env y extrae pares clave=valor
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^=]+)=(.*)$') {
        $envVars[$matches[1]] = $matches[2]   # Guardar variable en el hashtable
    }
}


# Configurar variables

$containerName = $envVars['DB_CONTAINER_NAME']   # Nombre del contenedor MySQL
#$dbName = $envVars['DB_NAME']
#$dbUSer = $envVars['DB_USER']
#$dbPass = $envVars['DB_PASS']
#$dbRootPass = $envVars['DB_ROOT_PASS']
$dbDataDir = $envVars['DB_DATADIR']              # Ruta interna donde MySQL guarda los datos
$dbLogDir = $envVars['DB_LOG_DIR']               # Ruta interna de logs de MySQL
$port = $envVars['DB_PORT']                      # Puerto de MySQL
$imageName = $envVars['DB_IMAGE_NAME']           # Imagen Docker a ejecutar
$networkName = $envVars['DB_NETWORK_NAME']       # Red Docker donde se conectará
$ip = $envVars["DB_IP"]                          # IP fija del contenedor



# Elimina contenedor si existe
if (docker ps -a --filter "name=^${containerName}$" --format "{{.Names}}" | Select-Object -First 1) {
    Write-Host "Eliminando contenedor existente: $containerName"
    docker stop $containerName 2>$null
    docker rm $containerName 2>$null
}

# Construye y ejecuta comando docker
$dockerCmd = @(
    "docker run -d",                              # Ejecutar en segundo plano
    "--name $containerName",                      # Nombre del contenedor
    "-p ${port}:${port}",                         # Mapear puerto MySQL
    "-v .\mysql_data:$dbDataDir",                 # Volumen de datos persistentes
    "-v .\logs\mysql:$dbLogDir",                  # Volumen de logs
    "--env-file $envFile",                        # Cargar variables de entorno
    "--hostname $containerName",                  # Hostname del contenedor
    "--network $networkName",                     # Conectar a la red Docker
    "--ip $ip",                                   # Asignar IP fija
    $imageName                                    # Imagen a ejecutar
) -join ' '

Write-Host "Ejecutando: $dockerCmd"
Invoke-Expression $dockerCmd   # Ejecuta comando final
