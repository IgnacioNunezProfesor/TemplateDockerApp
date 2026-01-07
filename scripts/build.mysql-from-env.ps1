# Define parámetros de entrada con valores por defecto
param(
    # Ruta al archivo de variables de entorno
    [string]$envFile = ".\env\dev.mysql.env"
)

# Hashtable para almacenar las variables de entorno leídas del archivo
$envVars = @{}

# Comprueba que el archivo de entorno exista
if (-not (Test-Path $envFile)) {
    # Si no existe, muestra un error y termina la ejecución
    Write-Error "Env file '$envFile' not found."
    exit 1
} 

# Lee el archivo de entorno línea por línea
Get-Content $envFile | ForEach-Object {

    # Comprueba si la línea tiene el formato clave=valor
    if ($_ -match '^\s*([^=]+)=(.*)$') {

        # Guarda la clave y el valor en la hashtable
        $envVars[$matches[1]] = $matches[2]
    }
}

# Obtiene la ruta al Dockerfile de la base de datos desde las variables de entorno
$Dockerfile = $envVars['DB_DOCKERFILE']

# Obtiene el nombre/tag de la imagen Docker de la base de datos
$Tag = $envVars['DB_IMAGE_NAME']

# Construye los argumentos --build-arg para Docker usando las variables de entorno
$buildArgsSTR = @(
    "--build-arg DB_USER=" + $envVars['DB_USER'],
    "--build-arg DB_PASS=" + $envVars['DB_PASS'],
    "--build-arg DB_ROOT_PASS=" + $envVars['DB_ROOT_PASS'],
    "--build-arg DB_DATADIR=" + $envVars['DB_DATADIR'],
    "--build-arg DB_PORT=" + $envVars['DB_PORT'],
    "--build-arg DB_NAME=" + $envVars['DB_NAME'],
    "--build-arg DB_LOG_DIR=" + $envVars['DB_LOG_DIR']
) -join ' '

# Construye el comando completo de Docker build
$cmddockerSTR = @('docker build', '--no-cache', '-f', $Dockerfile, '-t', $Tag, $buildArgsSTR, '.') -join ' '

# Muestra en pantalla el comando que se va a ejecutar
Write-Host "Ejecutando: docker $cmddockerSTR" 

# Ejecuta el comando Docker build
Invoke-Expression $cmddockerSTR

# Guarda el código de salida del comando Docker
$code = $LASTEXITCODE

# Si Docker build falla, muestra un error y termina con el mismo código
if ($code -ne 0) {
    Write-Error "docker build falló con código $code"
    exit $code
}
