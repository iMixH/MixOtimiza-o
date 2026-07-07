# ============================================================
# MIX PREFIX - MEMORY MODULE
# Arquivo: 02-Memory.ps1
# Compativel: Windows 10 / 11
# Autor: Mix Prefix
# ============================================================

Clear-Host
$Host.UI.RawUI.WindowTitle = "MIX PREFIX - MEMORY"
$ErrorActionPreference = "SilentlyContinue"

$pastaRelatorios = "$env:USERPROFILE\Desktop\MixPrefix_Relatorios"
if (-not (Test-Path $pastaRelatorios)) { New-Item -ItemType Directory -Path $pastaRelatorios | Out-Null }

function Line {
    Write-Host "============================================================" -ForegroundColor Cyan
}

function PauseMenu {
    Write-Host ""
    Read-Host "Pressione ENTER para voltar"
}

function Get-PageFileRecommendation {
    param($Ram)

    if ($Ram -le 4) {
        return @{ Initial = 4096; Maximum = 8192 }
    }
    elseif ($Ram -le 8) {
        return @{ Initial = 8192; Maximum = 16384 }
    }
    elseif ($Ram -le 16) {
        return @{ Initial = 16384; Maximum = 32768 }
    }
    elseif ($Ram -le 32) {
        return @{ Initial = 8192; Maximum = 16384 }
    }
    else {
        return @{ Initial = 4096; Maximum = 8192 }
    }
}

while ($true) {

    Clear-Host
    Line
    Write-Host "              MIX PREFIX MEMORY" -ForegroundColor Green
    Line
    Write-Host ""

    $os = Get-CimInstance Win32_OperatingSystem
    $cs = Get-CimInstance Win32_ComputerSystem

    $total = [math]::Round($cs.TotalPhysicalMemory / 1GB, 2)
    $free  = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
    $used  = [math]::Round($total - $free, 2)
    $usage = [math]::Round(($used / $total) * 100, 1)

    $page = Get-CimInstance Win32_PageFileUsage
    $pageSize = if ($page) { "$($page.AllocatedBaseSize) MB" } else { "Nao Detectado" }

    try {
        $compression = (Get-MMAgent).MemoryCompression
    } catch {
        $compression = "Desconhecido"
    }

    $recommend = Get-PageFileRecommendation $total

    Write-Host "RAM Instalada.............: $total GB"
    Write-Host "RAM Utilizada.............: $used GB"
    Write-Host "RAM Livre.................: $free GB"
    Write-Host "Uso.......................: $usage %"
    Write-Host ""

    if ($compression) {
        Write-Host "Memory Compression........: Ativada" -ForegroundColor Green
    } else {
        Write-Host "Memory Compression........: Desativada" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "PageFile Atual............: $pageSize"
    Write-Host ""
    Write-Host "Recomendado para este PC"
    Write-Host "Inicial...................: $($recommend.Initial) MB"
    Write-Host "Maximo....................: $($recommend.Maximum) MB"
    Write-Host ""

    if ($usage -lt 70) {
        Write-Host "STATUS....................: Excelente" -ForegroundColor Green
    }
    elseif ($usage -lt 85) {
        Write-Host "STATUS....................: Bom" -ForegroundColor Yellow
    }
    else {
        Write-Host "STATUS....................: RAM Muito Alta" -ForegroundColor Red
    }

    Write-Host ""
    Line
    Write-Host "[1] Atualizar Informacoes"
    Write-Host "[2] Ativar Memory Compression"
    Write-Host "[3] Desativar Memory Compression"
    Write-Host "[4] Abrir Configuracao de Memoria Virtual"
    Write-Host "[5] Gerar Relatorio"
    Write-Host "[0] Voltar"
    Write-Host ""

    $op = Read-Host "Escolha"

    switch ($op) {

        "1" { continue }

        "2" {
            Enable-MMAgent -MemoryCompression
            Write-Host ""
            Write-Host "Memory Compression Ativada." -ForegroundColor Green
            PauseMenu
        }

        "3" {
            Disable-MMAgent -MemoryCompression
            Write-Host ""
            Write-Host "Memory Compression Desativada." -ForegroundColor Yellow
            PauseMenu
        }

        "4" {
            Start-Process SystemPropertiesPerformance.exe
            PauseMenu
        }

        "5" {
            $arquivo = "$pastaRelatorios\Memory_Report_$(Get-Date -Format 'ddMMyyyy_HHmmss').txt"

            @"
==============================
MIX PREFIX MEMORY REPORT
$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
==============================

RAM Instalada....: $total GB
RAM em Uso.......: $used GB
RAM Livre........: $free GB
Uso..............: $usage %

Memory Compression: $(if($compression){"Ativada"}else{"Desativada"})

PageFile Atual....: $pageSize

Recomendado
Inicial...........: $($recommend.Initial) MB
Maximo............: $($recommend.Maximum) MB
"@ | Out-File $arquivo -Encoding UTF8

            Write-Host ""
            Write-Host "Relatorio salvo em: $arquivo" -ForegroundColor Green
            PauseMenu
        }

        "0" { break }

        default { PauseMenu }
    }
}