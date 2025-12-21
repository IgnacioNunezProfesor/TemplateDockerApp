# Obtener la ruta del repositorio actual
$repoPath = Get-Location

# Obtener la lista de submódulos
$submodules = git submodule status --recursive | ForEach-Object {
    $_ -replace '^\s*([+-]?\d+)\s+(\S+)\s+.*$', '$2'
}

# Eliminar cada submódulo
foreach ($submodule in $submodules) {
    Write-Host "Eliminando submódulo: $submodule"
    
    # Eliminar la entrada del submódulo del archivo .gitmodules
    (Get-Content "$repoPath\.gitmodules") -replace "^\s*\[submodule `"$submodule`"\].*?^\s*\[", "" -replace "^\s*\[submodule `"$submodule`"\].*?(\r?\n)+", "" | Set-Content "$repoPath\.gitmodules"
    
    # Eliminar la carpeta del submódulo
    Remove-Item -Recurse -Force "$repoPath\$submodule"
    
    # Eliminar la entrada del submódulo del índice de Git
    git rm --cached "$submodule"
}

# Confirmar los cambios
git commit -m "Eliminados submódulos"