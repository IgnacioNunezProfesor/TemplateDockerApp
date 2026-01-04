# Parámetro del script: archivo .env desde el que se cargarán las variables
param(
    [string]$envFile = ".\env\dev.mysql.env"
)

# Hashtable donde se almacenarán las variables del .env
$envVars = @{}

# Comprobar si el archivo .env existe
if (-not (Test-Path $envFile)) {
    Write-Error "Env file '$envFile' not found."
    exit 1
}

# Leer el archivo .env línea por línea
Get-Content $envFile | ForEach-Object {

# Coincide líneas con formato clave=valor
    if ($_ -match '^\s*([^=]+)=(.*)$') {

# Guarda clave y valor en el hashtable
        $envVars[$matches[1]] = $matches[2]
    }
}

# Extrae ruta del Dockerfile desde el .env
$Dockerfile = $envVars['DB_DOCKERFILE']

# Extrae nombre de la imagen desde el .env
$Tag = $envVars['DB_IMAGE_NAME']

# Construye los argumentos --build-arg para docker build
$buildArgsSTR = @(
    "--build-arg DB_USER=" + $envVars['DB_USER'],
    "--build-arg DB_PASS=" + $envVars['DB_PASS'],
    "--build-arg DB_ROOT_PASS=" + $envVars['DB_ROOT_PASS'],
    "--build-arg DB_DATADIR=" + $envVars['DB_DATADIR'],
    "--build-arg DB_PORT=" + $envVars['DB_PORT'],
    "--build-arg DB_NAME=" + $envVars['DB_NAME'],
    "--build-arg DB_LOG_DIR=" + $envVars['DB_LOG_DIR']
) -join ' '

# Construye el comando final de docker build como cadena
$cmddockerSTR = @(
    'docker build',
    '--no-cache',
    '-f', $Dockerfile,
    '-t', $Tag,
    $buildArgsSTR,
    '.'
) -join ' '

# Muestra el comando que se va a ejecutar
Write-Host "Ejecutando: docker $cmddockerSTR"

# Ejecuta docker build
Invoke-Expression $cmddockerSTR

# Comprueba código de salida
$code = $LASTEXITCODE
if ($code -ne 0) {
    Write-Error "docker build falló con código $code"
    exit $code
}
