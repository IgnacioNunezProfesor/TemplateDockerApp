# Define parámetros con valores por defecto
param(
    [string]$envFile = ".\env\dev.mysql.env"    # Ruta al archivo .env con la configuración del contenedor MySQL
)
$envVars = @{}      # Crea un diccionario vacío para guardar las variables clave=valor

# Verifica si el archivo .env existe
if (-not (Test-Path $envFile)) {
    # Muestra error si no se encuentra el archivo
    Write-Error "Env file '$envFile' not found."
    # Sale del script con código de error
    exit 1
} 

# Lee el archivo línea por línea y extrae las variables
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^=]+)=(.*)$') {    # Busca líneas con formato clave=valor usando expresión regular
        $envVars[$matches[1]] = $matches[2]     # Guarda la clave y el valor en el diccionario
    }
}


# Configurar variables a partir del diccionario
$containerName = $envVars['DB_CONTAINER_NAME']  # Nombre del contenedor MySQL
#$dbName = $envVars['DB_NAME']  # Nombre de la base de datos
#$dbUSer = $envVars['DB_USER']  # Usuario de la base de datos
#$dbPass = $envVars['DB_PASS']  # Contraseña del usuario
#$dbRootPass = $envVars['DB_ROOT_PASS']     # Contraseña del usuario root
$dbDataDir = $envVars['DB_DATADIR']     # Carpeta de datos de MySQL dentro del contenedor
$dbLogDir = $envVars['DB_LOG_DIR']      # Carpeta de logs de MySQL dentro del contenedor
$portMapping = $envVars['DB_PORT_MAPPING']      # Mapeo de puertos entre host y contenedor
$imageName = $envVars['DB_IMAGE_NAME']      # Nombre de la imagen Docker que se va a usar
$networkName = $envVars['DB_NETWORK_NAME']      # Nombre de la red Docker donde se conectará el contenedor
$ip = $envVars["DB_IP"]     # IP fija que se asignará al contenedor dentro de la red



# Eliminar contenedor si existe
if (docker ps -a --filter "name=^${containerName}$" --format "{{.Names}}" | Select-Object -First 1) {
    Write-Host "Eliminando contenedor existente: $containerName"    # Muestra mensaje si se encuentra un contenedor con ese nombre
    docker stop $containerName 2>$null  # Intenta detener el contenedor (ignora errores con 2>null)
    docker rm $containerName 2>$null    # Elimina el contenedor (ignora errores con 2>null)
}

# Construir y ejecutar comando docker
$dockerCmd = @(
    "docker run -d",    # Ejecuta el contenedor en segundo plano
    "--name $containerName",    # Asigna nombre al contenedor
    "-p $portMapping",      # Mapea puertos entre host y contenedor
    "-v .\mysql_data:$dbDataDir",       # Monta volumen local para datos persistentes
    "-v .\logs\mysql:$dbLogDir",    # Monta volumen local para logs
    "--env-file $envFile",      # Carga variables de entorno desde el archivo .env
    "--hostname $containerName",    # Asigna nombre de host al contenedor
    "--network $networkName",   # Conecta el contenedor a la red Docker especificada
    "--ip $ip",     # Asigna IP fija dentro de la red
    "--hostentry ${ip} mysqlhost",      # Añade entrada al /etc/hosts del contenedor
    $imageName  # Imagen Docker que se va a usar
) -join ' '     # Une todos los elementos en una sola cadena de texto

# Muestra el comando que se va a ejecutar
Write-Host "Ejecutando: $dockerCmd"
# Ejecuta el comando Docker
Invoke-Expression $dockerCmd