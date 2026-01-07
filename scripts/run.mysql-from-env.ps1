# Define parámetros de entrada con valores por defecto
param(
    # Archivo de variables de entorno
    [string]$envFile = ".\env\dev.mysql.env"
)

# Hashtable para almacenar las variables de entorno
$envVars = @{}

# Comprueba que el archivo de entorno exista
if (-not (Test-Path $envFile)) {
    # Si no existe, muestra un error y termina la ejecución
    Write-Error "Env file '$envFile' not found."
    exit 1
} 

# Leer el archivo de entorno línea por línea y almacenar clave=valor en la hashtable
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^=]+)=(.*)$') {
        $envVars[$matches[1]] = $matches[2]
    }
}

# Configurar variables locales desde la hashtable
$containerName = $envVars['DB_CONTAINER_NAME']   # Nombre del contenedor Docker
#$dbName = $envVars['DB_NAME']                   # Nombre de la base de datos (no usado aquí)
#$dbUser = $envVars['DB_USER']                   # Usuario de la base de datos (no usado aquí)
#$dbPass = $envVars['DB_PASS']                   # Contraseña del usuario (no usado aquí)
#$dbRootPass = $envVars['DB_ROOT_PASS']          # Contraseña root (no usado aquí)
$dbDataDir = $envVars['DB_DATADIR']             # Carpeta dentro del contenedor para los datos
$dbLogDir = $envVars['DB_LOG_DIR']              # Carpeta dentro del contenedor para logs
$portMapping = $envVars['DB_PORT_MAPPING']      # Puerto host:contenedor
$imageName = $envVars['DB_IMAGE_NAME']          # Imagen Docker a usar
$networkName = $envVars['DB_NETWORK_NAME']      # Red Docker
$ip = $envVars["DB_IP"]                          # IP fija del contenedor en la red

# Eliminar contenedor si ya existe
if (docker ps -a --filter "name=^${containerName}$" --format "{{.Names}}" | Select-Object -First 1) {
    # Mensaje indicando eliminación
    Write-Host "Eliminando contenedor existente: $containerName"

    # Detener y eliminar contenedor
    docker stop $containerName 2>$null
    docker rm $containerName 2>$null
}

# Construir el comando Docker para ejecutar el contenedor de base de datos
$dockerCmd = @(
    "docker run -d",                        # Ejecutar en segundo plano
    "--name $containerName",                 # Nombre del contenedor
    "-p $portMapping",                       # Mapeo de puertos host:contenedor
    "-v .\mysql_data:$dbDataDir",           # Montar volumen local para datos
    "-v .\logs\mysql:$dbLogDir",            # Montar volumen local para logs
    "--env-file $envFile",                   # Archivo de variables de entorno
    "--hostname $containerName",             # Nombre del host del contenedor
    "--network $networkName",                # Red Docker
    "--ip $ip",                              # IP fija del contenedor
    "--hostentry ${ip} mysqlhost",           # Entrada en /etc/hosts dentro del contenedor
    $imageName                               # Imagen Docker a usar
) -join ' '

# Mostrar en pantalla el comando que se va a ejecutar
Write-Host "Ejecutando: $dockerCmd"

# Ejecutar el contenedor Docker
Invoke-Expression $dockerCmd
