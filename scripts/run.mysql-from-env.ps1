# Define parameters with default values
param(
    [string]$envFile = ".\env\dev.mysql.env" # Ruta del archivo .env
)
$envVars = @{} # Diccionario donde se guardarán las variables del entorno

if (-not (Test-Path $envFile)) { # Comprueba si el archivo existe
    Write-Error "Env file '$envFile' not found." # Muestra error si no existe
    exit 1 # Finaliza el script
} 
Get-Content $envFile | ForEach-Object { # Lee el archivo línea por línea
    if ($_ -match '^\s*([^=]+)=(.*)$') { # Detecta líneas con formato clave=valor
        $envVars[$matches[1]] = $matches[2] # Guarda clave y valor en el diccionario
    }
}


# Configurar variables

$containerName = $envVars['DB_CONTAINER_NAME'] # Nombre del contenedor
#$dbName = $envVars['DB_NAME']
#$dbUSer = $envVars['DB_USER']
#$dbPass = $envVars['DB_PASS']
#$dbRootPass = $envVars['DB_ROOT_PASS']
$dbDataDir = $envVars['DB_DATADIR'] # Ruta interna donde MySQL almacena datos
$dbLogDir = $envVars['DB_LOG_DIR'] # Ruta interna donde MySQL almacena logs
$portMapping = $envVars['DB_PORT_MAPPING'] # Mapeo de puertos host:contenedor
$imageName = $envVars['DB_IMAGE_NAME'] # Nombre de la imagen Docker
$networkName = $envVars['DB_NETWORK_NAME'] # Nombre de la red Docker
$ip = $envVars["DB_IP"] # IP fija asignada al contenedor



# Eliminar contenedor si existe
if (docker ps -a --filter "name=^${containerName}$" --format "{{.Names}}" | Select-Object -First 1) { # Comprueba si el contenedor ya existe
    Write-Host "Eliminando contenedor existente: $containerName" # Mensaje informativo
    docker stop $containerName 2>$null # Detiene el contenedor
    docker rm $containerName 2>$null # Elimina el contenedor
}

# Construir y ejecutar comando docker
$dockerCmd = @(
    "docker run -d", # Ejecuta el contenedor en segundo plano
    "--name $containerName", # Asigna nombre al contenedor
    "-p $portMapping", # Mapea puertos
    "-v .\mysql_data:$dbDataDir", # Volumen persistente para datos
    "-v .\logs\mysql:$dbLogDir", # Volumen persistente para logs
    "--env-file $envFile", # Carga variables desde el archivo .env
    "--hostname $containerName", # Define el hostname interno
    "--network $networkName", # Conecta a la red Docker
    "--ip $ip", # Asigna IP fija
    "--hostentry ${ip} mysqlhost", # Añade entrada al /etc/hosts del contenedor
    $imageName # Imagen a ejecutar
) -join ' ' # Une todo en un solo comando

Write-Host "Ejecutando: $dockerCmd" # Muestra el comando final
Invoke-Expression $dockerCmd # Ejecuta el comando