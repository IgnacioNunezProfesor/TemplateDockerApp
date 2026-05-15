param(
    [Parameter(Mandatory=$true)]
    [string]$Target,

    [switch]$Sqlmap,
    [switch]$Wpscan,
    [switch]$Nikto,
    [switch]$Whatweb,
    [switch]$All,

    [string]$Output = "./securityreports"
)

# Crear carpeta de resultados con timestamp
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$folder = Join-Path $Output $timestamp
New-Item -ItemType Directory -Force -Path $folder | Out-Null

Write-Host "[+] Iniciando análisis sobre $Target"
Write-Host "[+] Resultados en: $folder"

# Funciones internas
function RunSqlmap {
    Write-Host "[SQLMAP] Ejecutando análisis..."
    sqlmap -u $Target `
        --batch `
        --crawl=3 `
        --level=5 `
        --risk=3 `
        --random-agent `
        --threads=5 `
        --output-dir="$folder/sqlmap" | Tee-Object "$folder/sqlmap.log"
}

function RunWpscan {
    Write-Host "[WPSCAN] Escaneando WordPress..."
    wpscan --url $Target --enumerate ap,at,cb,dbe,u,m --random-user-agent `
        | Tee-Object "$folder/wpscan.log"
}

function RunNikto {
    Write-Host "[NIKTO] Ejecutando análisis..."
    nikto -h $Target | Tee-Object "$folder/nikto.log"
}

function RunWhatweb {
    Write-Host "[WHATWEB] Fingerprinting..."
    whatweb $Target --log-verbose="$folder/whatweb.log"
}

# Lógica de ejecución
if ($All) {
    $Sqlmap = $Wpscan = $Nikto = $Whatweb = $true
}

if ($Sqlmap) { RunSqlmap }
if ($Wpscan) { RunWpscan }
if ($Nikto)  { RunNikto }
if ($Whatweb){ RunWhatweb }

Write-Host "[+] Análisis completado."
