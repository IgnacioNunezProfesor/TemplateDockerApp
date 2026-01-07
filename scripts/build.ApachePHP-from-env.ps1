# Script para construir imagen Docker de Apache+PHP desde archivo de entorno
# Lee variables de .env y las pasa como --build-arg al docker build

# Definir parámetros con valores por defecto
# $EnvFile: Ruta al archivo .env con variables de entorno
# $Dockerfile: Ruta al Dockerfile a construir
# $Tag: Etiqueta para la imagen Docker resultante
Param(
    [string]$EnvFile = ".\env\dev.apachephp.env",
    [string]$Dockerfile = "docker/http/apache+php/apache-php.dev.dockerfile",
    [string]$Tag = "apachephp:dev"
)

# Verificar que el archivo .env existe antes de continuar
if (-not (Test-Path $EnvFile)) {
    Write-Error "Env file '$EnvFile' not found."
    exit 1
}

# Leer todas las líneas del archivo .env
$lines = Get-Content $EnvFile -ErrorAction Stop
$buildArgs = @() # Array para almacenar argumentos de construcción

# Procesar cada línea del archivo .env
foreach ($line in $lines) {
    $line = $line.Trim() # Eliminar espacios al inicio/final

    # Saltar líneas vacías o comentarios (comienzan con #)
    if (-not $line -or $line.StartsWith('#')) { continue }

    # Saltar líneas que no contienen signo = (no son asignaciones)
    if ($line -notmatch '=') { continue }

    # Dividir línea en clave y valor (solo primera ocurrencia de =)
    $parts = $line -split '=', 2
    $k = $parts[0].Trim() # Nombre de la variable
    $v = $parts[1].Trim() # Valor de la variable
    # Remover comillas dobles si existen alrededor del valor
    if ($v.StartsWith('"') -and $v.EndsWith('"')) { $v = $v.Substring(1, $v.Length - 2) }
    # Remover comillas simples si existen alrededor del valor  
    if ($v.StartsWith("'") -and $v.EndsWith("'")) { $v = $v.Substring(1, $v.Length - 2) }
    # Agregar argumento al array en formato --build-arg clave=valor
    $buildArgs += '--build-arg'
    $buildArgs += "$k=$v"
}

# Construir array con todos los argumentos para docker build
# --no-cache: fuerza reconstrucción completa sin usar caché
# -f: especifica el Dockerfile a usar
# -t: etiqueta para la imagen
$argsSTR = @('build', '--no-cache', '-f', $Dockerfile, '-t', $Tag) + $buildArgs + '.'

# Mostrar comando que se ejecutará (para debugging/transparencia)
Write-Host "Ejecutando: docker $($argsSTR -join ' ')"
# Ejecutar comando docker build con splatting (@argsSTR)
# @argsSTR expande el array como argumentos separados
& docker @argsSTR
# Capturar código de salida del comando docker
$code = $LASTEXITCODE
# Verificar si docker build fue exitoso (código 0 = éxito)
if ($code -ne 0) {
    Write-Error "docker build falló con código $code"
    exit $code # Salir con mismo código de error
}