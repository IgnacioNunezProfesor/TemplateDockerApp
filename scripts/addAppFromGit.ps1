# Script para agregar submódulos Git desde repositorios remotos
# Uso: .\addAppFromGit.ps1 -SubmoduleName "nombre" -GitHubUrl "url" -DestinationPath "ruta"

# Definir parámetros obligatorios para el script
param(
    [Parameter(Mandatory=$true)] # Nombre debe ser proporcionado
    [string]$SubmoduleName,
    
    [Parameter(Mandatory=$true)] # URL del repositorio GitHub
    [string]$GitHubUrl,
    
    [Parameter(Mandatory=$true)] # Ruta destino dentro del proyecto
    [string]$DestinationPath
)

# Bloque try-catch para manejo de errores
try {
    # Mostrar información de lo que se va a hacer
    Write-Host "Adding submodule: $SubmoduleName"
    Write-Host "From: $GitHubUrl"
    Write-Host "To: $DestinationPath"
    
    # Ejecutar comando git para agregar submódulo
    git submodule add $GitHubUrl $DestinationPath
    
    # Verificar código de salida del comando git
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Submodule added successfully!" -ForegroundColor Green
    } else {
        Write-Host "Error adding submodule" -ForegroundColor Red
        exit 1 # Salir con código de error
    }
}
# Capturar cualquier excepción no manejada
catch {
    Write-Host "Exception: $_" -ForegroundColor Red
    exit 1  # Salir con código de error
}