<#
    Script: deploy.ApachePHP.ps1
    Autor: Ignacio
    Función:
        - Cargar variables desde dev.apachephp.env y dev.mysql.env
        - Ejecutar build y run
        - Sustituir variables en moodle.config.php
        - Copiar config.php al contenedor
#>

Write-Host "=== Cargando variables de entorno ===" -ForegroundColor Cyan

# Archivos .env
$envApache = ".\env\dev.apachephp.env"
$envMysql = ".\env\dev.mysql.env"

$envFiles = @($envApache, $envMysql)

foreach ($file in $envFiles) {
    if (!(Test-Path $file)) {
        Write-Host "ERROR: No se encuentra $file" -ForegroundColor Red
        exit 1
    }

    Get-Content $file | ForEach-Object {
        if ($_ -match "^\s*#" -or $_ -match "^\s*$") { return }
        $parts = $_ -split "=", 2
        if ($parts.Count -eq 2) {
            $name = $parts[0].Trim()
            $value = $parts[1].Trim()
            Set-Item -Path Env:$name -Value $value
        }
    }
}

Write-Host "Variables cargadas correctamente." -ForegroundColor Green

# Ejecutar scripts existentes
Write-Host "`n=== Ejecutando build.ApachePHP-from-env.ps1 ===" -ForegroundColor Cyan
if (!(Test-Path ".\scripts\build.ApachePHP-from-env.ps1")) {
    Write-Host "ERROR: No existe build.ApachePHP-from-env.ps1" -ForegroundColor Red
    exit 1
}
.\scripts\build.ApachePHP-from-env.ps1
Write-Host "`n=== Ejecutando run.ApachePHP-from-env.ps1 ===" -ForegroundColor Cyan
if (!(Test-Path ".\scripts\run.ApachePHP-from-env.ps1")) {
    Write-Host "ERROR: No existe run.ApachePHP-from-env.ps1" -ForegroundColor Red
    exit 1
}
.\scripts\run.ApachePHP-from-env.ps1

# Sustitución de variables en config.php
Write-Host "`n=== Generando config.php con valores reales ===" -ForegroundColor Cyan

$moodleConfigTemplate = ".\CurrentAppAssets\appconfig\moodle.config.php"
$tempConfig = ".\CurrentAppAssets\appconfig\config.php"

if (!(Test-Path $moodleConfigTemplate)) {
    Write-Host "ERROR: No se encuentra $moodleConfigTemplate" -ForegroundColor Red
    exit 1
}

# Cargar plantilla
$content = Get-Content $moodleConfigTemplate -Raw

# Mapeo entre variables Moodle y variables reales
$mapping = @{
    "MOODLE_DB_HOST"   = $Env:DB_CONTAINER_NAME
    "MOODLE_DB_NAME"   = $Env:DB_NAME
    "MOODLE_DB_USER"   = $Env:DB_USER
    "MOODLE_DB_PASS"   = $Env:DB_PASS
    "MOODLE_URL"       = $Env:SERVER_NAME
    "MOODLE_DATA_PATH" = $Env:DATA_FOLDER
}

foreach ($key in $mapping.Keys) {
    $value = $mapping[$key]

    if (-not $value) {
        Write-Host "ADVERTENCIA: La variable $key no tiene valor asignado." -ForegroundColor Yellow
        continue
    }

    # Sustituir getenv('VAR') por 'valor'
    $pattern = "getenv\('$key'\)"
    $replacement = "'$value'"

    $content = $content -replace $pattern, $replacement
}

# Guardar archivo final
Set-Content -Path $tempConfig -Value $content -Encoding UTF8

Write-Host "Archivo config.php generado correctamente." -ForegroundColor Green

# Copiar al contenedor
$container = $Env:CONTAINER_NAME
$datafolder = $Env:DATA_FOLDER



if (-not $container) {
    Write-Host "ERROR: CONTAINER_NAME no está definido" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Copiando config.php al contenedor $container ===" -ForegroundColor Cyan

docker cp $tempConfig "${container}:${datafolder}/config.php"

if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: No se pudo copiar config.php al contenedor" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Configuración copiada correctamente ===" -ForegroundColor Green
Write-Host "Archivo: config.php → /var/www/apache/config.php"
Write-Host "Contenedor: $container"
Write-Host "`n=== Despliegue completado ===" -ForegroundColor Green
