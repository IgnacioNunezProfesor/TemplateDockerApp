# Parámetros del script con valores por defecto
Param(
# Archivo .env desde el que se leerán las variables de build
    [string]$EnvFile = ".\env\dev.apachephp.env",

# Dockerfile que se usará para construir la imagen
    [string]$Dockerfile = "docker/http/apache+php/apache-php.dev.dockerfile",

# Nombre y etiqueta de la imagen resultante
    [string]$Tag = "apachephp:dev"
)

# Comprueba si el archivo .env existe
if (-not (Test-Path $EnvFile)) {
    Write-Error "Env file '$EnvFile' not found."
    exit 1
}

# Lee todas las líneas del archivo .env
$lines = Get-Content $EnvFile -ErrorAction Stop

# Array donde se almacenarán los argumentos --build-arg
$buildArgs = @()

# Recorre cada línea del archivo .env
foreach ($line in $lines) {

# Elimina espacios al inicio y final
    $line = $line.Trim()

# Salta líneas vacías o comentarios
    if (-not $line -or $line.StartsWith('#')) { continue }

# Salta líneas que no tengan formato clave=valor
    if ($line -notmatch '=') { continue }

# Separa clave y valor
    $parts = $line -split '=', 2
    $k = $parts[0].Trim()
    $v = $parts[1].Trim()

# Quita comillas dobles si existen
    if ($v.StartsWith('"') -and $v.EndsWith('"')) {
        $v = $v.Substring(1, $v.Length - 2)
    }

# Quita comillas simples si existen
    if ($v.StartsWith("'") -and $v.EndsWith("'")) {
        $v = $v.Substring(1, $v.Length - 2)
    }

# Añade argumento de build a la lista
    $buildArgs += '--build-arg'
    $buildArgs += "$k=$v"
}

# Construye el comando final para docker build
$argsSTR = @('build', '--no-cache', '-f', $Dockerfile, '-t', $Tag) + $buildArgs + '.'

# Muestra el comando que se ejecutará
Write-Host "Ejecutando: docker $($argsSTR -join ' ')"

# Ejecuta docker build con los argumentos generados
& docker @argsSTR

# Comprueba código de salida
$code = $LASTEXITCODE
if ($code -ne 0) {
    Write-Error "docker build falló con código $code"
    exit $code
}
