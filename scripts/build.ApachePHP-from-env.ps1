# Parámetros de entrada del script con valores por defecto
Param(
    # Ruta del archivo de variables de entorno
    [string]$EnvFile = ".\env\dev.apachephp.env",
    
    # Ruta al Dockerfile a usar para construir la imagen
    [string]$Dockerfile = "docker/http/apache+php/apache-php.dev.dockerfile",
    
    # Nombre/Tag de la imagen Docker que se creará
    [string]$Tag = "apachephp:dev"
)

# Comprueba que el archivo de entorno exista
if (-not (Test-Path $EnvFile)) {
    # Si no existe, muestra un error y finaliza la ejecución
    Write-Error "Env file '$EnvFile' not found."
    exit 1
}

# Lee todas las líneas del archivo de entorno
$lines = Get-Content $EnvFile -ErrorAction Stop

# Array que contendrá los argumentos --build-arg para Docker
$buildArgs = @()

# Recorre todas las líneas del archivo de entorno
foreach ($line in $lines) {

    # Elimina espacios en blanco al inicio y al final
    $line = $line.Trim()

    # Ignora líneas vacías o comentarios que empiezan con #
    if (-not $line -or $line.StartsWith('#')) { continue }

    # Ignora líneas que no contienen un '='
    if ($line -notmatch '=') { continue }

    # Divide la línea en clave y valor
    $parts = $line -split '=', 2
    $k = $parts[0].Trim()
    $v = $parts[1].Trim()

    # Quita comillas dobles alrededor del valor, si existen
    if ($v.StartsWith('"') -and $v.EndsWith('"')) { $v = $v.Substring(1, $v.Length - 2) }

    # Quita comillas simples alrededor del valor, si existen
    if ($v.StartsWith("'") -and $v.EndsWith("'")) { $v = $v.Substring(1, $v.Length - 2) }

    # Añade el argumento para Docker
    $buildArgs += '--build-arg'
    $buildArgs += "$k=$v"
}

# Construye la cadena de argumentos final para el comando docker build
$argsSTR = @('build', '--no-cache', '-f', $Dockerfile, '-t', $Tag) + $buildArgs + '.'

# Muestra por pantalla el comando que se va a ejecutar
Write-Host "Ejecutando: docker $($argsSTR -join ' ')"

# Ejecuta el comando docker build con los argumentos construidos
& docker @argsSTR

# Guarda el código de salida del comando docker
$code = $LASTEXITCODE

# Si docker build falla, muestra un error y finaliza con el mismo código
if ($code -ne 0) {
    Write-Error "docker build falló con código $code"
    exit $code
}
