# ============================================================
# MIX PREFIX - HARDWARE PROFILE MODULE
# Arquivo: 07-HardwareProfile.ps1
# Compativel: Windows 10 / 11
# Autor: Mix Prefix
# ============================================================

Clear-Host
$Host.UI.RawUI.WindowTitle = "MIX PREFIX - HARDWARE PROFILE"
$ErrorActionPreference = "SilentlyContinue"

$pastaRelatorios = "$env:USERPROFILE\Desktop\MixPrefix_Relatorios"
if (-not (Test-Path $pastaRelatorios)) { New-Item -ItemType Directory -Path $pastaRelatorios | Out-Null }

function Line {
    Write-Host "============================================================" -ForegroundColor Cyan
}

$cpu     = Get-CimInstance Win32_Processor
$gpu     = Get-CimInstance Win32_VideoController | Select-Object -First 1
$ram     = Get-CimInstance Win32_ComputerSystem
$disk    = Get-PhysicalDisk | Select-Object -First 1
$os      = Get-CimInstance Win32_OperatingSystem
$adapter = Get-NetAdapter | Where-Object Status -eq "Up" | Select-Object -First 1

$TotalRAM = [math]::Round($ram.TotalPhysicalMemory / 1GB)
$CPUName  = $cpu.Name
$GPUName  = $gpu.Name
$DiskType = if ($disk) { $disk.MediaType } else { "N/D" }
$Cores    = $cpu.NumberOfCores
$Threads  = $cpu.NumberOfLogicalProcessors

$AdapterName  = if ($adapter) { $adapter.Name } else { "Nenhum adaptador ativo" }
$AdapterSpeed = if ($adapter) { $adapter.LinkSpeed } else { "N/D" }

$ProfileName = "Universal"
$Reason = "Configuracao nao identificada nos perfis padrao; classificado por desempenho geral."

# Deteccao por nome de CPU (mais precisa)
if ($CPUName -match "Ryzen 9" -and $TotalRAM -ge 16) {
    $ProfileName = "Gamer Extreme"
    $Reason = "CPU topo de linha e memoria suficiente para cargas pesadas."
}
elseif ($CPUName -match "i9") {
    $ProfileName = "Gamer Extreme"
    $Reason = "Processador de altissimo desempenho."
}
elseif ($CPUName -match "Ryzen 7" -and $TotalRAM -ge 16) {
    $ProfileName = "Gamer High"
    $Reason = "CPU de alto desempenho e memoria suficiente."
}
elseif ($CPUName -match "i7") {
    $ProfileName = "Performance"
    $Reason = "Processador indicado para jogos e produtividade."
}
elseif ($CPUName -match "Ryzen 5" -and $TotalRAM -ge 16) {
    $ProfileName = "Gamer Mid"
    $Reason = "Bom equilibrio para jogos e trabalho."
}
elseif ($CPUName -match "i5") {
    $ProfileName = "Balanced"
    $Reason = "Perfil equilibrado para uso geral e jogos leves/medios."
}
elseif ($CPUName -match "Xeon") {
    $ProfileName = "Workstation"
    $Reason = "Perfil focado em multitarefa e cargas profissionais."
}
elseif ($CPUName -match "Ryzen 3" -or $CPUName -match "i3") {
    $ProfileName = "Entry Level"
    $Reason = "Hardware de entrada; priorizar leveza no dia a dia."
}
elseif ($CPUName -match "A8" -or $CPUName -match "A6" -or $CPUName -match "A4" -or $CPUName -match "Celeron" -or $CPUName -match "Pentium") {
    $ProfileName = "Low End"
    $Reason = "Hardware antigo/basico; priorizar leveza e evitar multitarefa pesada."
}
# Fallback por nucleos/threads quando o nome nao bate com nenhum padrao acima
elseif ($Threads -ge 16 -and $TotalRAM -ge 16) {
    $ProfileName = "Gamer High"
    $Reason = "Alto numero de nucleos/threads e memoria suficiente."
}
elseif ($Threads -ge 8 -and $TotalRAM -ge 8) {
    $ProfileName = "Balanced"
    $Reason = "Configuracao intermediaria com boa quantidade de threads."
}
elseif ($Threads -le 4 -or $TotalRAM -lt 8) {
    $ProfileName = "Low End"
    $Reason = "Poucos nucleos/threads ou memoria limitada; priorizar leveza."
}

Clear-Host
Line
Write-Host "            MIX PREFIX HARDWARE PROFILE" -ForegroundColor Green
Line
Write-Host ""

Write-Host "CPU"
Write-Host "--------------------------------------------"
Write-Host "$CPUName ($Cores nucleos / $Threads threads)"
Write-Host ""

Write-Host "GPU"
Write-Host "--------------------------------------------"
Write-Host $GPUName
Write-Host ""

Write-Host "RAM"
Write-Host "--------------------------------------------"
Write-Host "$TotalRAM GB"
Write-Host ""

Write-Host "Disco"
Write-Host "--------------------------------------------"
Write-Host "$DiskType"
Write-Host ""

Write-Host "Windows"
Write-Host "--------------------------------------------"
Write-Host $os.Caption
Write-Host ""

Write-Host "Rede"
Write-Host "--------------------------------------------"
Write-Host "$AdapterName"
Write-Host "$AdapterSpeed"
Write-Host ""

Line
Write-Host "PERFIL RECOMENDADO" -ForegroundColor Yellow
Line
Write-Host ""
Write-Host "Perfil : $ProfileName"
Write-Host ""
Write-Host "Motivo : $Reason"
Write-Host ""

$Recomendacoes = switch ($ProfileName) {

    "Gamer Extreme" {
        @(
            "Plano Alto Desempenho"
            "Discord/Overlays desativados durante jogos"
            "Drivers de GPU sempre atualizados"
            "SSD com pelo menos 20% livre"
            "Manter RAM abaixo de 85%"
        )
    }

    "Gamer High" {
        @(
            "Plano Alto Desempenho"
            "Discord sem Overlay"
            "Drivers GPU atualizados"
            "SSD com pelo menos 20% livre"
            "Manter RAM abaixo de 85%"
        )
    }

    "Performance" {
        @(
            "Bom para jogos e produtividade"
            "Manter drivers atualizados"
            "Limpeza periodica de disco"
        )
    }

    "Gamer Mid" {
        @(
            "Fechar programas desnecessarios em background"
            "Plano Alto Desempenho"
            "Atualizar drivers regularmente"
        )
    }

    "Balanced" {
        @(
            "Equilibrar jogos e produtividade"
            "Limpeza semanal de TEMP/Prefetch"
        )
    }

    "Workstation" {
        @(
            "Priorizar estabilidade para multitarefa"
            "Manter SSD com espaco livre"
            "Evitar softwares desnecessarios em segundo plano"
        )
    }

    "Entry Level" {
        @(
            "Evitar rodar muitos programas ao mesmo tempo"
            "Manter o sistema limpo e atualizado"
            "Preferir jogos/apps mais leves"
        )
    }

    "Low End" {
        @(
            "Evitar multitarefa pesada"
            "Manter Windows limpo, sem programas de inicializacao desnecessarios"
            "Considerar upgrade de RAM/SSD se possivel"
        )
    }

    default {
        @("Perfil generico; recomendacoes basicas de manutencao.")
    }
}

Write-Host "Recomendacoes:"
$Recomendacoes | ForEach-Object { Write-Host "- $_" }

$arquivo = "$pastaRelatorios\Hardware_Profile_Report_$(Get-Date -Format 'ddMMyyyy_HHmmss').txt"

@"
==============================
MIX PREFIX HARDWARE REPORT
$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
==============================

CPU..........: $CPUName ($Cores nucleos / $Threads threads)
GPU..........: $GPUName
RAM..........: $TotalRAM GB
DISCO........: $DiskType
WINDOWS......: $($os.Caption)
REDE.........: $AdapterName ($AdapterSpeed)

PERFIL.......: $ProfileName
MOTIVO.......: $Reason

RECOMENDACOES:
$($Recomendacoes -join "`n")
"@ | Out-File $arquivo -Encoding UTF8

Write-Host ""
Write-Host "Relatorio salvo em: $arquivo" -ForegroundColor Green
Write-Host ""
Read-Host "Pressione ENTER para voltar ao menu"