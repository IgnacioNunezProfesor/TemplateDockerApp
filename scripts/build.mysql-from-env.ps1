# Define parameters with default values
# Script para construir imagen Docker de MySQL desde variables de entorno
# Versión alternativa que extrae configuración del mismo archivo .env

# Definir parámetro con valor por defecto
# $envFile: Ruta al archivo de entorno con configuración MySQL
param(
    [string]$envFile = ".\env\dev.mysql.env"
)
# Hashtable para almacenar variables de entorno
$envVars = @{}

# Verificar existencia del archivo .env
if (-not (Test-Path $envFile)) {
    Write-Error "Env file '$envFile' not found."
    exit 1 # Terminar con error si archivo no existe
} 
# Leer archivo .env línea por línea
Get-Content $envFile | ForEach-Object {
    # Expresión regular: captura clave=valor (ignorando espacios iniciales)
    # ^\s*: cero o más espacios al inicio
    # ([^=]+): uno o más caracteres que no sean =
    # =(.*)$: signo = seguido de cualquier cosa hasta fin de línea
    if ($_ -match '^\s*([^=]+)=(.*)$') {
        # Agregar al hashtable: clave = grupo 1, valor = grupo 2
        $envVars[$matches[1]] = $matches[2]
    }
}
# Extraer valores específicos del hashtable
$Dockerfile = $envVars['DB_DOCKERFILE']
$Tag = $envVars['DB_IMAGE_NAME']
# Construir string con todos los argumentos --build-arg
# Se concatenan todos los argumentos en un solo string
$buildArgsSTR = @(
    "--build-arg DB_USER=" + $envVars['DB_USER'],
    "--build-arg DB_PASS=" + $envVars['DB_PASS'],
    "--build-arg DB_ROOT_PASS=" + $envVars['DB_ROOT_PASS'],
    "--build-arg DB_DATADIR=" + $envVars['DB_DATADIR'],
    "--build-arg DB_PORT=" + $envVars['DB_PORT'],
    "--build-arg DB_NAME=" + $envVars['DB_NAME'],
    "--build-arg DB_LOG_DIR=" + $envVars['DB_LOG_DIR']
) -join ' ' # Unir todos con espacios

# Construir comando docker build completo como string
# Nota: usando Invoke-Expression en lugar de & para ejecutar string
$cmddockerSTR = @('docker build', '--no-cache', '-f', $Dockerfile, '-t', $Tag, $buildArgsSTR, '.') -join ' '

# Mostrar comando a ejecutar
Write-Host "Ejecutando: docker $cmddockerSTR"

# Ejecutar comando usando Invoke-Expression (evalúa string como PowerShell)
Invoke-Expression $cmddockerSTR

# Capturar código de salida
$code = $LASTEXITCODE

# Verificar éxito de la operación
if ($code -ne 0) {
    Write-Error "docker build falló con código $code"
    exit $code # Propagar código de error
}