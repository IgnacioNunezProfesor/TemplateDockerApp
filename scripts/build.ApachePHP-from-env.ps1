# Este bloque define los parámetros de entrada del script. Si no se pasan valores al ejecutarlo, se usarán los que aparecen por defecto.
Param(
    [string]$EnvFile = ".\env\dev.apachephp.env", # Ruta al archivo .env con las variables necesarias
    [string]$Dockerfile = "docker/http/apache+php/apache-php.dev.dockerfile", # Ruta al Dockerfile que se va a usar
    [string]$Tag = "apachephp:dev" # Etiqueta que tendrá la imagen Docker generada
)

# Aquí se verifica si el archivo .env existe.
# Si no se encuentra, muestra un error y sale del script para evitar errores posteriores.
if (-not (Test-Path $EnvFile)) {
    Write-Error "Env file '$EnvFile' not found."
    exit 1
}

# Guarda todas las líneas del archivo .env como texto.
$lines = Get-Content $EnvFile -ErrorAction Stop
# Una lista donde se irán añadiendo los --build-arg que se pasarán al comando docker build
$buildArgs = @()

# Convierte cada línea válida del archivo .env en un argumento --build-arg para el comando docker build
foreach ($line in $lines) {
    $line = $line.Trim()    # Elimina espacios al principio y al final de la línea
    if (-not $line -or $line.StartsWith('#')) { continue }  # Si la línea está vacía o es un comentario, la salta
    if ($line -notmatch '=') { continue }   # Si no contiene un "=", no es una variable válida, la salta
    $parts = $line -split '=', 2    # Divide la línea en dos partes: clave y valor
    $k = $parts[0].Trim()   # Limpia la clave (nombre de la variable)
    $v = $parts[1].Trim()   # Limpia el valor (contenido de la variable)
    if ($v.StartsWith('"') -and $v.EndsWith('"')) { $v = $v.Substring(1, $v.Length - 2) }   # Si el valor está entre comillas triples, las elimina
    if ($v.StartsWith("'") -and $v.EndsWith("'")) { $v = $v.Substring(1, $v.Length - 2) }   # Si el valor está entre comillas dobles, también las elimina
    $buildArgs += '--build-arg'     # Añade el argumento de construcción para Docker
    $buildArgs += "$k=$v"   # Añade la variable en formato clave=valor
}

# Construye el array de argumentos para el comando docker build 
# Incluye: build sin caché, Dockerfile, etiqueta de imagen, argumentos de entorno y el contexto (.)
$argsSTR = @('build', '--no-cache', '-f', $Dockerfile, '-t', $Tag) + $buildArgs + '.'

# Muestra en pantalla el comando que se va a ejecutar
# Ejecuta el comando docker build con todos los argumentos
Write-Host "Ejecutando: docker $($argsSTR -join ' ')" & docker @argsSTR

# Guarda el código de salida del comando
$code = $LASTEXITCODE

# Si el código no es 0, muestra un error y termina el script con ese código
if ($code -ne 0) {
    Write-Error "docker build falló con código $code"
    exit $code
}
