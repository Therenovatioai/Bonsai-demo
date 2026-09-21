$ErrorActionPreference = "Stop"

$root = "$HOME\AI\Bonsai-demo"
$launcher = Join-Path $root "scripts\start_llama_server.ps1"
$template = Join-Path $root "templates\chat_template.jinja"

if (-not (Test-Path $launcher)) {
    throw "No se encontró: $launcher"
}

if (-not (Test-Path $template)) {
    throw "No se encontró: $template"
}

# Evitar ejecutar Qwen y Bonsai al mismo tiempo.
$qwen = Get-Process -Name "llama-kvmem-server" -ErrorAction SilentlyContinue

if ($qwen) {
    throw "Qwen/KVMem está ejecutándose. Deténlo antes de iniciar Bonsai."
}

# Evitar una segunda instancia de Bonsai.
$bonsai = Get-Process -Name "llama-server" -ErrorAction SilentlyContinue

if ($bonsai) {
    throw "Ya existe un llama-server ejecutándose."
}

# Configuración Bonsai.
$env:BONSAI_FAMILY = "bonsai2"
$env:BONSAI_MODEL = "27B"
$env:BONSAI_CTX = "262144"
$env:BONSAI_KV4 = "1"
$env:BONSAI_MMPROJ_CPU = "1"

Write-Host ""
Write-Host "Iniciando Bonsai 2 27B" -ForegroundColor Cyan
Write-Host "Contexto: 262144"
Write-Host "Puerto: 8080"
Write-Host "Parallel slots: 1 - modo secuencial"
Write-Host "Chat template: $template"
Write-Host ""

Push-Location $root

try {
    & $launcher `
        --alias bonsai2-27b `
        -np 1 `
        --chat-template-file $template `r`n        --image-min-tokens 1024
}
finally {
    Pop-Location
}

