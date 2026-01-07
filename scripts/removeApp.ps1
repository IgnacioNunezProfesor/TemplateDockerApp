# Elimina TODOS los submódulos de un repositorio Git
# Ignacio: este script limpia .gitmodules, .git/config, .git/modules y el working tree
Write-Host "Detectando submódulos..." -ForegroundColor Cyan

# 1. Obtener lista de submódulos desde .gitmodules
$gitmodules = ".gitmodules" # Archivo que contiene configuración de submódulos

# Verificar si el archivo .gitmodules existe
if (!(Test-Path $gitmodules)) {
    Write-Host "No existe .gitmodules. No hay submódulos que eliminar." -ForegroundColor Yellow
    exit # Terminar script si no hay submódulos
}

# Leer rutas de submódulos usando Select-String (similar a grep)
# Busca líneas que contengan 'path = ' y extrae la ruta
$submodules = Select-String -Path $gitmodules -Pattern "path = " | ForEach-Object {
    ($_ -split "path = ")[1].Trim() # Extraer parte después de 'path = '
}

# Verificar si se encontraron submódulos
if ($submodules.Count -eq 0) {
    Write-Host "No se encontraron submódulos en .gitmodules." -ForegroundColor Yellow
    exit # Terminar si no hay submódulos
}

# Mostrar lista de submódulos detectados
Write-Host "Submódulos detectados:" -ForegroundColor Green
$submodules | ForEach-Object { Write-Host " - $_" }

# 2. Eliminar cada submódulo uno por uno
foreach ($sub in $submodules) {

    Write-Host "`nEliminando submódulo: $sub" -ForegroundColor Cyan

    # Deinit: desinicializar submódulo (elimina configuración)
    # -f: force, no pregunta confirmación
    git submodule deinit -f $sub | Out-Null

    # Eliminar del índice Git (staging area)
    git rm -f $sub | Out-Null

    # Eliminar carpeta física del working tree
    if (Test-Path $sub) {
        Remove-Item -Recurse -Force $sub # Eliminar recursivamente
        Write-Host "Carpeta eliminada: $sub"
    }

    # Eliminar carpeta interna en .git/modules (metadatos del submódulo)
    $modulePath = ".git/modules/$sub" # Ruta donde Git guarda info del submódulo
    if (Test-Path $modulePath) {
        Remove-Item -Recurse -Force $modulePath
        Write-Host "Carpeta interna eliminada: $modulePath"
    }
}

# 3. Eliminar archivo .gitmodules (ya no es necesario)
Remove-Item -Force ".gitmodules"
Write-Host "`nArchivo .gitmodules eliminado." -ForegroundColor Green

# 4. Commit final con todos los cambios
git add -A git add -A  # Agregar todos los cambios al staging
git commit -m "Remove all submodules" | Out-Null # Commit silencioso

Write-Host "`n✅ Todos los submódulos han sido eliminados completamente." -ForegroundColor Green
