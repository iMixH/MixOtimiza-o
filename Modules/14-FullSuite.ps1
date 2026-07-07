# ============================================================
# MIX OTIMIZACOES - FULL SUITE MODULE
# Arquivo: 14-FullSuite.ps1
# ============================================================

Clear-Host
$Host.UI.RawUI.WindowTitle = "MIX OTIMIZACOES - FULL SUITE"
$ErrorActionPreference = "SilentlyContinue"

$pastaRelatorios = "$env:USERPROFILE\Desktop\MixPrefix_Relatorios"
if (-not (Test-Path $pastaRelatorios)) { New-Item -ItemType Directory -Path $pastaRelatorios | Out-Null }

function Line {
    Write-Host "============================================================" -ForegroundColor Cyan
}

function PauseMenu {
    Write-Host ""
    Read-Host "Pressione ENTER para voltar ao menu"
}

function Confirmar($mensagem) {
    Write-Host ""
    Write-Host $mensagem -ForegroundColor Yellow
    $r = Read-Host "Deseja continuar? (S/N)"
    return ($r -eq "S" -or $r -eq "s")
}

function Log-Alteracao($texto) {
    $logFile = "$pastaRelatorios\FullSuite_Log.txt"
    "$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') - $texto" | Out-File $logFile -Append -Encoding UTF8
}

# --- Deteccao de perfil (mesma logica do modulo Hardware Profile) ---
function Get-PerfilHardware {
    $cpu = Get-CimInstance Win32_Processor
    $ram = Get-CimInstance Win32_ComputerSystem
    $totalRam = [math]::Round($ram.TotalPhysicalMemory / 1GB)
    $threads = $cpu.NumberOfLogicalProcessors
    $cpuName = $cpu.Name

    if ($cpuName -match "Ryzen 9" -and $totalRam -ge 16) { return "Gamer Extreme" }
    elseif ($cpuName -match "i9") { return "Gamer Extreme" }
    elseif ($cpuName -match "Ryzen 7" -and $totalRam -ge 16) { return "Gamer High" }
    elseif ($cpuName -match "i7") { return "Performance" }
    elseif ($cpuName -match "Ryzen 5" -and $totalRam -ge 16) { return "Gamer Mid" }
    elseif ($cpuName -match "i5") { return "Balanced" }
    elseif ($cpuName -match "Xeon") { return "Workstation" }
    elseif ($cpuName -match "Ryzen 3" -or $cpuName -match "i3") { return "Entry Level" }
    elseif ($cpuName -match "Celeron|Pentium|A8|A6|A4") { return "Low End" }
    elseif ($threads -ge 16 -and $totalRam -ge 16) { return "Gamer High" }
    elseif ($threads -ge 8 -and $totalRam -ge 8) { return "Balanced" }
    else { return "Low End" }
}

$ServicosOpcionais = @("XblAuthManager","XblGameSave","XboxNetApiSvc","XboxGipSvc","SysMain","DiagTrack","WSearch","Fax","PrintNotify","MapsBroker","RetailDemo")

Clear-Host
Line
Write-Host "              MIX OTIMIZACOES - FULL SUITE" -ForegroundColor Green
Line
Write-Host ""

$perfil = Get-PerfilHardware
Write-Host "Perfil de Hardware Detectado: $perfil" -ForegroundColor Cyan
Write-Host ""
Write-Host "Este modulo aplica um conjunto de otimizacoes recomendadas" -ForegroundColor DarkGray
Write-Host "para o seu perfil de hardware, por categoria." -ForegroundColor DarkGray
Write-Host ""

Line
Write-Host "Categorias que serao aplicadas:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  [A] Limpeza (TEMP, Prefetch, Lixeira, DNS)"
Write-Host "  [B] Servicos Opcionais Desativados (Xbox, SysMain, Telemetria, etc)"
Write-Host "  [C] Plano de Energia Alto Desempenho"
Write-Host "  [D] Efeitos Visuais Reduzidos"
Write-Host "  [E] Game Mode Ativado"
Write-Host ""
Line
Write-Host ""

$respostas = @{}
foreach ($cat in @("A","B","C","D","E")) {
    $nome = switch ($cat) {
        "A" { "Limpeza" }
        "B" { "Desativar Servicos Opcionais" }
        "C" { "Plano de Energia Alto Desempenho" }
        "D" { "Reduzir Efeitos Visuais" }
        "E" { "Ativar Game Mode" }
    }
    $r = Read-Host "Aplicar [$cat] $nome ? (S/N)"
    $respostas[$cat] = ($r -eq "S" -or $r -eq "s")
}

Write-Host ""
if (-not (Confirmar "Confirma a aplicacao das categorias selecionadas?")) {
    Write-Host ""
    Write-Host "Operacao cancelada." -ForegroundColor Yellow
    Read-Host "Pressione ENTER para voltar ao menu"
    exit
}

Write-Host ""
Write-Host "Aplicando otimizacoes..." -ForegroundColor Cyan
Write-Host ""

$resumo = @()

# --- A: Limpeza ---
if ($respostas["A"]) {
    Write-Host "[A] Limpando arquivos temporarios..." -ForegroundColor White
    Remove-Item "$env:TEMP\*" -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item "$env:windir\Temp\*" -Force -Recurse -ErrorAction SilentlyContinue
    Remove-Item "$env:windir\Prefetch\*" -Force -Recurse -ErrorAction SilentlyContinue
    ipconfig /flushdns | Out-Null
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Log-Alteracao "Limpeza completa executada"
    $resumo += "Limpeza: TEMP, Prefetch, Lixeira e DNS limpos."
    Write-Host "    Concluido." -ForegroundColor Green
}

# --- B: Servicos ---
if ($respostas["B"]) {
    Write-Host "[B] Desativando servicos opcionais..." -ForegroundColor White
    $desativados = 0
    foreach ($nomeServico in $ServicosOpcionais) {
        $svc = Get-Service -Name $nomeServico -ErrorAction SilentlyContinue
        if ($svc -and $svc.Status -eq "Running") {
            Stop-Service -Name $nomeServico -Force -ErrorAction SilentlyContinue
            Set-Service -Name $nomeServico -StartupType Disabled -ErrorAction SilentlyContinue
            Log-Alteracao "Servico desativado: $nomeServico"
            $desativados++
        }
    }
    $resumo += "Servicos: $desativados servico(s) opcional(is) desativado(s)."
    Write-Host "    Concluido. ($desativados servicos)" -ForegroundColor Green
}

# --- C: Energia ---
if ($respostas["C"]) {
    Write-Host "[C] Ativando plano de Alto Desempenho..." -ForegroundColor White
    powercfg /setactive SCHEME_MIN
    Log-Alteracao "Plano de energia alterado para Alto Desempenho"
    $resumo += "Energia: Plano Alto Desempenho ativado."
    Write-Host "    Concluido." -ForegroundColor Green
}

# --- D: Visual ---
if ($respostas["D"]) {
    Write-Host "[D] Reduzindo efeitos visuais..." -ForegroundColor White
    $pathVisualFX = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    if (-not (Test-Path $pathVisualFX)) { New-Item -Path $pathVisualFX -Force | Out-Null }
    New-ItemProperty -Path $pathVisualFX -Name "VisualFXSetting" -Value 2 -PropertyType DWord -Force | Out-Null
    Log-Alteracao "Efeitos visuais reduzidos"
    $resumo += "Visual: Efeitos visuais reduzidos para modo desempenho."
    Write-Host "    Concluido." -ForegroundColor Green
}

# --- E: Game Mode ---
if ($respostas["E"]) {
    Write-Host "[E] Ativando Game Mode..." -ForegroundColor White
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 1 -ErrorAction SilentlyContinue
    Log-Alteracao "Game Mode ativado"
    $resumo += "Game Mode: Ativado."
    Write-Host "    Concluido." -ForegroundColor Green
}

Write-Host ""
Line
Write-Host "OTIMIZACAO COMPLETA FINALIZADA" -ForegroundColor Green
Line
Write-Host ""
Write-Host "Resumo do que foi aplicado:" -ForegroundColor Cyan
foreach ($item in $resumo) {
    Write-Host "  - $item"
}

$arquivo = "$pastaRelatorios\FullSuite_Report_$(Get-Date -Format 'ddMMyyyy_HHmmss').txt"

@"
==============================
MIX OTIMIZACOES FULL SUITE REPORT
$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
==============================

PERFIL DETECTADO: $perfil

CATEGORIAS APLICADAS:
$($resumo -join "`n")

Consulte FullSuite_Log.txt para o historico detalhado de cada alteracao.

Recomendacao: rode o modulo System Score antes e depois desta
otimizacao completa para ver a evolucao da nota do seu PC.
"@ | Out-File $arquivo -Encoding UTF8

Write-Host ""
Write-Host "Relatorio salvo em: $arquivo" -ForegroundColor Green
Write-Host ""
Read-Host "Pressione ENTER para voltar ao menu"