# Elimina TODOS los submódulos de un repositorio Git
# Ignacio: este script limpia .gitmodules, .git/config, .git/modules y el working tree

# Mensaje inicial
Write-Host "Detectando submódulos..." -ForegroundColor Cyan

# 1. Obtener lista de submódulos desde .gitmodules
$gitmodules = ".gitmodules"

# Comprueba si existe el archivo .gitmodules
if (!(Test-Path $gitmodules)) {
    Write-Host "No existe .gitmodules. No hay submódulos que eliminar." -ForegroundColor Yellow
    exit
}

# Lee rutas de submódulos buscando líneas con "path = ..."
$submodules = Select-String -Path $gitmodules -Pattern "path = " | ForEach-Object {
    ($_ -split "path = ")[1].Trim()
}

# Si no hay submódulos definidos, salir
if ($submodules.Count -eq 0) {
    Write-Host "No se encontraron submódulos en .gitmodules." -ForegroundColor Yellow
    exit
}

# Muestra lista de submódulos detectados
Write-Host "Submódulos detectados:" -ForegroundColor Green
$submodules | ForEach-Object { Write-Host " - $_" }

# 2. Elimina cada submódulo encontrado
foreach ($sub in $submodules) {

    Write-Host "`nEliminando submódulo: $sub" -ForegroundColor Cyan

# Quita configuración del submódulo
    git submodule deinit -f $sub | Out-Null

# Elimina del índice de Git
    git rm -f $sub | Out-Null

# Elimina carpeta física del submódulo
    if (Test-Path $sub) {
        Remove-Item -Recurse -Force $sub
        Write-Host "Carpeta eliminada: $sub"
    }

# Elimina carpeta interna dentro de .git/modules
    $modulePath = ".git/modules/$sub"
    if (Test-Path $modulePath) {
        Remove-Item -Recurse -Force $modulePath
        Write-Host "Carpeta interna eliminada: $modulePath"
    }
}

# 3. Elimina archivo .gitmodules
Remove-Item -Force ".gitmodules"
Write-Host "`nArchivo .gitmodules eliminado." -ForegroundColor Green

# 4. Commit final para registrar los cambios
git add -A
git commit -m "Remove all submodules" | Out-Null

# Mensaje final
Write-Host "`n✅ Todos los submódulos han sido eliminados completamente." -ForegroundColor Green

