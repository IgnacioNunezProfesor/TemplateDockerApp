# Define parameters with default values 
param(
    [string]$envFile = ".\env\dev.mysql.env" # Ruta del archivo .env
)
$envVars = @{} # Diccionario donde se guardarán las variables del .env

if (-not (Test-Path $envFile)) { # Comprueba si existe el archivo .env
    Write-Error "Env file '$envFile' not found." # Muestra error si no existe
    exit 1 # Sale con código 1
} 

Get-Content $envFile | ForEach-Object { # Lee el archivo línea por línea
    if ($_ -match '^\s*([^=]+)=(.*)$') { # Detecta líneas con formato clave=valor
        $envVars[$matches[1]] = $matches[2] # Guarda clave y valor en el diccionario
    }
}

$Dockerfile = $envVars['DB_DOCKERFILE'] # Obtiene la ruta del Dockerfile desde el .env
$Tag = $envVars['DB_IMAGE_NAME'] # Obtiene el nombre/tag de la imagen

$buildArgsSTR = @( # Construye los argumentos --build-arg
    "--build-arg DB_USER=" + $envVars['DB_USER'], # Usuario de la BD
    "--build-arg DB_PASS=" + $envVars['DB_PASS'], # Contraseña del usuario
    "--build-arg DB_ROOT_PASS=" + $envVars['DB_ROOT_PASS'], # Contraseña de root
    "--build-arg DB_DATADIR=" + $envVars['DB_DATADIR'], # Directorio de datos
    "--build-arg DB_PORT=" + $envVars['DB_PORT'], # Puerto de MySQL
    "--build-arg DB_NAME=" + $envVars['DB_NAME'], # Nombre de la BD
    "--build-arg DB_LOG_DIR=" + $envVars['DB_LOG_DIR'] # Ruta de logs
) -join ' ' # Une todos los argumentos en una sola cadena

$cmddockerSTR = @('docker build', '--no-cache', '-f', $Dockerfile, '-t', $Tag, $buildArgsSTR, '.') -join ' ' # Construye el comando final

Write-Host "Ejecutando: docker $cmddockerSTR" # Muestra el comando que se ejecutará
Invoke-Expression $cmddockerSTR # Ejecuta docker build
$code = $LASTEXITCODE # Captura el código de salida

if ($code -ne 0) { # Si docker build falló
    Write-Error "docker build falló con código $code" # Muestra error
    exit $code # Sale con el mismo código
}
