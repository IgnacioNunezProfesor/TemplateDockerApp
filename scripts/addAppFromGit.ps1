# Declaración de parámetros obligatorios del script
param(
# Nombre del submódulo que se añadirá al repositorio
    [Parameter(Mandatory=$true)]
    [string]$SubmoduleName,
    
# URL del repositorio GitHub que se añadirá como submódulo
    [Parameter(Mandatory=$true)]
    [string]$GitHubUrl,
    
# Ruta donde se almacenará el submódulo dentro del proyecto
    [Parameter(Mandatory=$true)]
    [string]$DestinationPath
)

try {
# Muestra información inicial al usuario
    Write-Host "Adding submodule: $SubmoduleName"
    Write-Host "From: $GitHubUrl"
    Write-Host "To: $DestinationPath"
    
# Ejecuta el comando para añadir el submódulo
    git submodule add $GitHubUrl $DestinationPath
    
# Comprueba si el comando anterior se ejecutó correctamente
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Submodule added successfully!" -ForegroundColor Green
    } else {
        Write-Host "Error adding submodule" -ForegroundColor Red
        exit 1
    }
}
catch {
# Captura y muestra cualquier excepción ocurrida durante la ejecución
    Write-Host "Exception: $_" -ForegroundColor Red
    exit 1
}
