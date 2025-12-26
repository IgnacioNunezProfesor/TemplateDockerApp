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

# Ejecutar scripts de MySQL
Write-Host "`n=== Ejecutando build.mysql-from-env.ps1 ===" -ForegroundColor Cyan
if (!(Test-Path ".\scripts\build.mysql-from-env.ps1")) {
    Write-Host "ERROR: No existe build.mysql-from-env.ps1" -ForegroundColor Red
    exit 1
}
.\scripts\build.mysql-from-env.ps1

Write-Host "`n=== Ejecutando run.mysql-from-env.ps1 ===" -ForegroundColor Cyan
if (!(Test-Path ".\scripts\run.mysql-from-env.ps1")) {
    Write-Host "ERROR: No existe run.mysql-from-env.ps1" -ForegroundColor Red
    exit 1
}
.\scripts\run.mysql-from-env.ps1

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


# Obtener variables de entorno necesarias para la instalación
$container = $env:APACHE_CONTAINER_NAME
$cliPath = "${FOLDER_NAME}/admin/cli/install.php"
$dbhost = $env:MYSQL_HOST
$dbname = $env:MYSQL_DATABASE
$dbuser = $env:MYSQL_USER
$dbpass = $env:MYSQL_PASSWORD
$dbport = $env:MYSQL_PORT
$wwwroot = $env:MOODLE_URL
$datadir = $env:MOODLE_DATA

Write-Host "`n=== Ejecutando instalación de Moodle ===" -ForegroundColor Cyan

# Ejecutar script de instalación con variables de entorno
docker exec -it $container php $cliPath `
    --dbtype=mysqli `
    --dbhost=$dbhost `
    --dbname=$dbname `
    --dbuser=$dbuser `
    --dbpass=$dbpass `
    --dbport=$dbport `
    --wwwroot=$wwwroot `
    --datadir=$datadir `
    --fullname="Moodle en Docker" `
    --shortname="MoodleDocker" `
    --adminuser="admin" `
    --adminpass="Admin123!" `
    --lang=es `
    --non-interactive `
    --agree-license



if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Falló la ejecución de install.php" -ForegroundColor Red
    exit 1
}

Write-Host "install.php ejecutado correctamente. Base de datos actualizada/creada." -ForegroundColor Green

Write-Host "`n=== Despliegue completado ===" -ForegroundColor Green
