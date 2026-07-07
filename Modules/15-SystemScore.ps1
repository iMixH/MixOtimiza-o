# ============================================================
# MIX OTIMIZACOES - SYSTEM SCORE MODULE
# Arquivo: 15-SystemScore.ps1
# ============================================================

Clear-Host
$Host.UI.RawUI.WindowTitle = "MIX OTIMIZACOES - SYSTEM SCORE"
$ErrorActionPreference = "SilentlyContinue"

$pastaRelatorios = "$env:USERPROFILE\Desktop\MixPrefix_Relatorios"
if (-not (Test-Path $pastaRelatorios)) { New-Item -ItemType Directory -Path $pastaRelatorios | Out-Null }

function Line {
    Write-Host "============================================================" -ForegroundColor Cyan
}

function Barra($percent) {
    $blocos = [math]::Round($percent / 5)
    $cheio = "#" * $blocos
    $vazio = "-" * (20 - $blocos)
    return "[$cheio$vazio] $percent%"
}

Clear-Host
Line
Write-Host "              MIX OTIMIZACOES SYSTEM SCORE" -ForegroundColor Green
Line
Write-Host ""
Write-Host "Analisando seu sistema..." -ForegroundColor Cyan
Write-Host ""

$pontos = 0
$maxPontos = 0
$detalhes = @()

# --- 1. RAM disponivel (peso 20) ---
$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
$totalRam = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
$freeRam = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$usoRam = [math]::Round((($totalRam - $freeRam) / $totalRam) * 100, 1)

$maxPontos += 20
if ($usoRam -lt 60) { $pRam = 20 }
elseif ($usoRam -lt 75) { $pRam = 14 }
elseif ($usoRam -lt 85) { $pRam = 8 }
else { $pRam = 3 }
$pontos += $pRam
$detalhes += [PSCustomObject]@{ Categoria = "Uso de RAM"; Nota = "$pRam/20"; Info = "$usoRam% em uso" }

# --- 2. Espaco em disco livre (peso 20) ---
$diskC = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$totalDisk = [math]::Round($diskC.Size / 1GB, 2)
$freeDisk = [math]::Round($diskC.FreeSpace / 1GB, 2)
$percLivre = [math]::Round(($freeDisk / $totalDisk) * 100, 1)

$maxPontos += 20
if ($percLivre -gt 30) { $pDisk = 20 }
elseif ($percLivre -gt 15) { $pDisk = 14 }
elseif ($percLivre -gt 5) { $pDisk = 7 }
else { $pDisk = 2 }
$pontos += $pDisk
$detalhes += [PSCustomObject]@{ Categoria = "Espaco Livre em Disco"; Nota = "$pDisk/20"; Info = "$freeDisk GB livres ($percLivre%)" }

# --- 3. Arquivos temporarios acumulados (peso 15) ---
function FolderSize($Path) {
    if (Test-Path $Path) {
        $size = (Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
        if ($size) { return $size }
    }
    return 0
}
$tempMB = [math]::Round(((FolderSize $env:TEMP) + (FolderSize "$env:windir\Temp")) / 1MB, 1)

$maxPontos += 15
if ($tempMB -lt 500) { $pTemp = 15 }
elseif ($tempMB -lt 2000) { $pTemp = 10 }
elseif ($tempMB -lt 5000) { $pTemp = 5 }
else { $pTemp = 1 }
$pontos += $pTemp
$detalhes += [PSCustomObject]@{ Categoria = "Arquivos Temporarios"; Nota = "$pTemp/15"; Info = "$tempMB MB acumulados" }

# --- 4. Programas de inicializacao (peso 15) ---
$startupCount = (Get-CimInstance Win32_StartupCommand | Measure-Object).Count

$maxPontos += 15
if ($startupCount -le 5) { $pStartup = 15 }
elseif ($startupCount -le 10) { $pStartup = 10 }
elseif ($startupCount -le 15) { $pStartup = 5 }
else { $pStartup = 2 }
$pontos += $pStartup
$detalhes += [PSCustomObject]@{ Categoria = "Programas na Inicializacao"; Nota = "$pStartup/15"; Info = "$startupCount programas" }

# --- 5. Fragmentacao / tipo de disco (peso 10) ---
$disk = Get-PhysicalDisk | Select-Object -First 1
$maxPontos += 10
if ($disk.MediaType -eq "SSD") { $pDiskType = 10 }
elseif ($disk.MediaType -eq "HDD") { $pDiskType = 6 }
else { $pDiskType = 5 }
$pontos += $pDiskType
$detalhes += [PSCustomObject]@{ Categoria = "Tipo de Armazenamento"; Nota = "$pDiskType/10"; Info = "$($disk.MediaType)" }

# --- 6. Tempo de atividade / ultima reinicializacao (peso 10) ---
$uptime = (Get-Date) - $os.LastBootUpTime
$diasUptime = [math]::Round($uptime.TotalDays, 1)

$maxPontos += 10
if ($diasUptime -lt 3) { $pUptime = 10 }
elseif ($diasUptime -lt 7) { $pUptime = 7 }
elseif ($diasUptime -lt 15) { $pUptime = 4 }
else { $pUptime = 1 }
$pontos += $pUptime
$detalhes += [PSCustomObject]@{ Categoria = "Tempo Desde Reinicio"; Nota = "$pUptime/10"; Info = "$diasUptime dias ligado" }

# --- 7. Windows atualizado (peso 10) ---
$build = [int]$os.BuildNumber
$maxPontos += 10
if ($build -ge 22000) { $pWin = 10 }
elseif ($build -ge 19041) { $pWin = 7 }
else { $pWin = 3 }
$pontos += $pWin
$detalhes += [PSCustomObject]@{ Categoria = "Versao do Windows"; Nota = "$pWin/10"; Info = "Build $build" }

# --- Calculo final ---
$scoreFinal = [math]::Round(($pontos / $maxPontos) * 100)

$classificacao = if ($scoreFinal -ge 90) { "EXCELENTE" }
    elseif ($scoreFinal -ge 75) { "BOM" }
    elseif ($scoreFinal -ge 55) { "REGULAR" }
    elseif ($scoreFinal -ge 35) { "RUIM" }
    else { "CRITICO" }

$cor = if ($scoreFinal -ge 75) { "Green" } elseif ($scoreFinal -ge 55) { "Yellow" } else { "Red" }

Clear-Host
Line
Write-Host "              MIX OTIMIZACOES SYSTEM SCORE" -ForegroundColor Green
Line
Write-Host ""
Write-Host "NOTA GERAL DO SEU PC" -ForegroundColor Cyan
Write-Host ""
Write-Host (Barra $scoreFinal) -ForegroundColor $cor
Write-Host ""
Write-Host "$scoreFinal / 100 pontos -- Classificacao: $classificacao" -ForegroundColor $cor
Write-Host ""
Line
Write-Host "DETALHAMENTO" -ForegroundColor Cyan
Line
Write-Host ""

foreach ($d in $detalhes) {
    Write-Host "$($d.Categoria)" -ForegroundColor White
    Write-Host "  Nota: $($d.Nota)  |  $($d.Info)" -ForegroundColor DarkGray
    Write-Host ""
}

Line
Write-Host "RECOMENDACOES PARA MELHORAR SUA NOTA" -ForegroundColor Yellow
Line
Write-Host ""

$piores = $detalhes | Sort-Object { [int]($_.Nota -split "/")[0] } | Select-Object -First 3
foreach ($p in $piores) {
    $sugestao = switch ($p.Categoria) {
        "Uso de RAM" { "Va ao modulo Memory e verifique processos consumindo RAM." }
        "Espaco Livre em Disco" { "Va ao modulo Cleaner e rode a Limpeza Completa." }
        "Arquivos Temporarios" { "Va ao modulo Cleaner e limpe TEMP do Windows/Usuario." }
        "Programas na Inicializacao" { "Va ao modulo Startup e desative programas desnecessarios." }
        "Tipo de Armazenamento" { "Considere migrar para um SSD, se ainda estiver em HDD." }
        "Tempo Desde Reinicio" { "Reinicie o computador periodicamente para liberar recursos." }
        "Versao do Windows" { "Mantenha o Windows atualizado via Windows Update." }
        default { "Consulte os modulos relacionados." }
    }
    Write-Host "- $sugestao"
}

$arquivo = "$pastaRelatorios\SystemScore_Report_$(Get-Date -Format 'ddMMyyyy_HHmmss').txt"
$linhasDetalhe = $detalhes | ForEach-Object { "  $($_.Categoria): $($_.Nota) - $($_.Info)" }

@"
==============================
MIX OTIMIZACOES SYSTEM SCORE REPORT
$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
==============================

NOTA GERAL: $scoreFinal / 100 ($classificacao)

DETALHAMENTO:
$($linhasDetalhe -join "`n")

Dica: rode este modulo novamente apos usar os outros modulos de
otimizacao (Cleaner, GameBoost, Startup) para ver sua nota melhorar.
"@ | Out-File $arquivo -Encoding UTF8

Write-Host ""
Write-Host "Relatorio salvo em: $arquivo" -ForegroundColor Green
Write-Host ""
Read-Host "Pressione ENTER para voltar ao menu"