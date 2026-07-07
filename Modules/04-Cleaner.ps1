# ============================================================
# MIX PREFIX - CLEANER MODULE
# Arquivo: 04-Cleaner.ps1
# Compativel: Windows 10 / 11
# Autor: Mix Prefix
# ============================================================

Clear-Host
$Host.UI.RawUI.WindowTitle = "MIX PREFIX - CLEANER"
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

function FolderSize($Path) {
    if (Test-Path $Path) {
        $size = (Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue |
                 Measure-Object Length -Sum).Sum
        if ($size) { return $size }
    }
    return 0
}

function Confirmar($mensagem) {
    Write-Host ""
    Write-Host $mensagem -ForegroundColor Yellow
    $r = Read-Host "Deseja continuar? (S/N)"
    return ($r -eq "S" -or $r -eq "s")
}

while ($true) {
    Clear-Host
    Line
    Write-Host "               MIX PREFIX CLEANER" -ForegroundColor Green
    Line
    Write-Host ""
    Write-Host "[1] Limpar TEMP do Usuario"
    Write-Host "[2] Limpar TEMP do Windows"
    Write-Host "[3] Limpar Prefetch"
    Write-Host "[4] Limpar Cache DNS"
    Write-Host "[5] Esvaziar Lixeira"
    Write-Host "[6] Limpeza Completa"
    Write-Host "[7] Gerar Relatorio"
    Write-Host "[0] Voltar"
    Write-Host ""
    $op = Read-Host "Escolha"

    switch ($op) {

        "1" {
            $temp = $env:TEMP
            $before = FolderSize $temp
            Remove-Item "$temp\*" -Force -Recurse -ErrorAction SilentlyContinue
            $after = FolderSize $temp
            $freed = [math]::Round(($before - $after) / 1MB, 2)
            Write-Host ""
            Write-Host "TEMP limpo." -ForegroundColor Green
            Write-Host "Liberado: $freed MB"
            PauseMenu
        }

        "2" {
            $win = "$env:windir\Temp"
            $before = FolderSize $win
            Remove-Item "$win\*" -Force -Recurse -ErrorAction SilentlyContinue
            $after = FolderSize $win
            $freed = [math]::Round(($before - $after) / 1MB, 2)
            Write-Host ""
            Write-Host "Windows Temp limpo." -ForegroundColor Green
            Write-Host "Liberado: $freed MB"
            PauseMenu
        }

        "3" {
            $pref = "$env:windir\Prefetch"
            $before = FolderSize $pref
            Remove-Item "$pref\*" -Force -Recurse -ErrorAction SilentlyContinue
            $after = FolderSize $pref
            $freed = [math]::Round(($before - $after) / 1MB, 2)
            Write-Host ""
            Write-Host "Prefetch limpo." -ForegroundColor Green
            Write-Host "Liberado: $freed MB"
            PauseMenu
        }

        "4" {
            ipconfig /flushdns
            PauseMenu
        }

        "5" {
            Clear-RecycleBin -Force -ErrorAction SilentlyContinue
            Write-Host ""
            Write-Host "Lixeira esvaziada." -ForegroundColor Green
            PauseMenu
        }

        "6" {
            if (Confirmar "Isso vai limpar TEMP, Windows Temp, Prefetch, Cache DNS e Lixeira.") {
                $totalBefore = (FolderSize $env:TEMP) + (FolderSize "$env:windir\Temp") + (FolderSize "$env:windir\Prefetch")

                Write-Host ""
                Write-Host "Executando limpeza..."
                Remove-Item "$env:TEMP\*" -Force -Recurse -ErrorAction SilentlyContinue
                Remove-Item "$env:windir\Temp\*" -Force -Recurse -ErrorAction SilentlyContinue
                Remove-Item "$env:windir\Prefetch\*" -Force -Recurse -ErrorAction SilentlyContinue
                ipconfig /flushdns
                Clear-RecycleBin -Force -ErrorAction SilentlyContinue

                $totalAfter = (FolderSize $env:TEMP) + (FolderSize "$env:windir\Temp") + (FolderSize "$env:windir\Prefetch")
                $freedTotal = [math]::Round(($totalBefore - $totalAfter) / 1MB, 2)

                Write-Host ""
                Write-Host "Limpeza concluida." -ForegroundColor Green
                Write-Host "Total liberado: $freedTotal MB"
            }
            PauseMenu
        }

        "7" {
            $tempSize = [math]::Round((FolderSize $env:TEMP) / 1MB, 2)
            $winSize  = [math]::Round((FolderSize "$env:windir\Temp") / 1MB, 2)
            $prefSize = [math]::Round((FolderSize "$env:windir\Prefetch") / 1MB, 2)

            $arquivo = "$pastaRelatorios\Cleaner_Report_$(Get-Date -Format 'ddMMyyyy_HHmmss').txt"

            @"
=============================
MIX PREFIX CLEANER REPORT
$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
=============================

TEMP Usuario......: $tempSize MB
Windows TEMP......: $winSize MB
Prefetch..........: $prefSize MB
"@ | Out-File $arquivo -Encoding UTF8

            Write-Host ""
            Write-Host "Relatorio salvo em: $arquivo" -ForegroundColor Green
            PauseMenu
        }

        "0" {
            break
        }

        default {
            PauseMenu
        }
    }
}