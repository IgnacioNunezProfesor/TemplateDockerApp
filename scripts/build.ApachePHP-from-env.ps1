Param( # Parámetros del script
    [string]$EnvFile = ".\env\dev.apachephp.env", # Ruta del archivo .env
    [string]$Dockerfile = "docker/http/apache+php/apache-php.dev.dockerfile", # Dockerfile a usar
    [string]$Tag = "apachephp:dev" # Tag de la imagen a generar
)

if (-not (Test-Path $EnvFile)) { # Comprueba si existe el archivo .env
    Write-Error "Env file '$EnvFile' not found." # Error si no existe
    exit 1 # Sale con código 1
}

$lines = Get-Content $EnvFile -ErrorAction Stop # Lee el archivo .env
$buildArgs = @() # Array donde se guardarán los argumentos --build-arg

foreach ($line in $lines) { # Recorre cada línea del .env
    $line = $line.Trim() # Elimina espacios
    if (-not $line -or $line.StartsWith('#')) { continue } # Ignora líneas vacías o comentarios
    if ($line -notmatch '=') { continue } # Ignora líneas sin "="
    $parts = $line -split '=', 2 # Divide clave y valor
    $k = $parts[0].Trim() # Clave
    $v = $parts[1].Trim() # Valor
    if ($v.StartsWith('"') -and $v.EndsWith('"')) { $v = $v.Substring(1, $v.Length - 2) } # Quita comillas dobles
    if ($v.StartsWith("'") -and $v.EndsWith("'")) { $v = $v.Substring(1, $v.Length - 2) } # Quita comillas simples
    $buildArgs += '--build-arg' # Añade flag
    $buildArgs += "$k=$v" # Añade argumento formateado
}

$argsSTR = @('build', '--no-cache', '-f', $Dockerfile, '-t', $Tag) + $buildArgs + '.' # Construye comando final

Write-Host "Ejecutando: docker $($argsSTR -join ' ')" & docker @argsSTR # Ejecuta docker build
$code = $LASTEXITCODE # Captura código de salida
if ($code -ne 0) { # Si hubo error
    Write-Error "docker build falló con código $code" # Muestra error
    exit $code # Sale con el mismo código
}