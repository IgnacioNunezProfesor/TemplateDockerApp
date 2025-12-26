# Define parámetros con valores por defecto
param(
    [string]$envFile = ".\env\dev.mysql.env"    # Ruta al archivo .env con las variables para MySQL
)
$envVars = @{}  # Crea un diccionario vacío para guardar las variables clave=valor

# Verifica si el archivo .env existe
if (-not (Test-Path $envFile)) {
    Write-Error "Env file '$envFile' not found."    # Muestra error si no se encuentra el archivo
    exit 1  # Sale del script con código de error
} 

# Lee el archivo línea por línea y extrae las variables
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([^=]+)=(.*)$') {    # Busca líneas con formato clave=valor
        $envVars[$matches[1]] = $matches[2] # Guarda la clave y el valor en el diccionario
    }
}

# Recupera valores específicos del diccionario para usarlos en el build
$Dockerfile = $envVars['DB_DOCKERFILE'] # Ruta al Dockerfile para MySQL
$Tag = $envVars['DB_IMAGE_NAME']    # Nombre/etiqueta de la imagen Docker
# Construye los argumentos --build-arg para docker build usando las variables del .env
$buildArgsSTR = @(
    "--build-arg DB_USER=" + $envVars['DB_USER'],
    "--build-arg DB_PASS=" + $envVars['DB_PASS'],
    "--build-arg DB_ROOT_PASS=" + $envVars['DB_ROOT_PASS'],
    "--build-arg DB_DATADIR=" + $envVars['DB_DATADIR'],
    "--build-arg DB_PORT=" + $envVars['DB_PORT'],
    "--build-arg DB_NAME=" + $envVars['DB_NAME'],
    "--build-arg DB_LOG_DIR=" + $envVars['DB_LOG_DIR']
) -join ' ' # Une todos los argumentos en un solo string para el comando

# Construye el comando completo docker build como una cadena de texto
# Incluye: build sin caché, Dockerfile, etiqueta, argumentos de entorno y contexto actual (.)
$cmddockerSTR = @('docker build', '--no-cache', '-f', $Dockerfile, '-t', $Tag, $buildArgsSTR, '.') -join ' '

# Muestra en pantalla el comando que se va a ejecutar
Write-Host "Ejecutando: docker $cmddockerSTR" 
# Ejecuta el comando usando Invoke-Expression
Invoke-Expression $cmddockerSTR
# Guarda el código de salida del comando
$code = $LASTEXITCODE
# Si el código no es 0, muestra un error y termina el script con ese código
if ($code -ne 0) {
    Write-Error "docker build falló con código $code"
    exit $code
}