# ============================================================
# MIX OTIMIZACOES - DRIVERS CHECK MODULE
# Arquivo: 07-DriversCheck.ps1
# ============================================================

Clear-Host
$Host.UI.RawUI.WindowTitle = "MIX OTIMIZACOES - DRIVERS"
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

function Get-DriversCriticos {
    $todos = Get-CimInstance Win32_PnPSignedDriver | Where-Object { $_.DeviceName -and $_.DriverVersion }
    $gpu = $todos | Where-Object { $_.DeviceClass -eq "DISPLAY" }
    $net = $todos | Where-Object { $_.DeviceClass -eq "NET" }
    $chip = $todos | Where-Object { $_.DeviceClass -eq "SYSTEM" -or $_.DeviceName -match "Chipset" }
    return @{ GPU = $gpu; Rede = $net; Chipset = $chip }
}

while ($true) {

    Clear-Host
    Line
    Write-Host "              MIX OTIMIZACOES - DRIVERS CHECK" -ForegroundColor Green
    Line
    Write-Host ""
    Write-Host "[1] Ver Drivers de GPU"
    Write-Host "[2] Ver Drivers de Rede"
    Write-Host "[3] Ver Drivers de Chipset/Sistema"
    Write-Host "[4] Listar Todos os Drivers com Data"
    Write-Host "[5] Verificar Drivers com Problema (Device Manager)"
    Write-Host "[6] Gerar Relatorio Completo"
    Write-Host "[0] Voltar"
    Write-Host ""

    $op = Read-Host "Escolha"

    switch ($op) {

        "1" {
            Write-Host ""
            Write-Host "Drivers de GPU:" -ForegroundColor Cyan
            $drivers = (Get-DriversCriticos).GPU
            foreach ($d in $drivers) {
                Write-Host ""
                Write-Host "Dispositivo.....: $($d.DeviceName)"
                Write-Host "Fabricante......: $($d.Manufacturer)"
                Write-Host "Versao..........: $($d.DriverVersion)"
                Write-Host "Data............: $($d.DriverDate)"
            }
            if (-not $drivers) { Write-Host "Nenhum driver de GPU detectado via WMI." }
            Write-Host ""
            Write-Host "Dica: confira a versao mais recente direto no site do fabricante" -ForegroundColor Yellow
            Write-Host "(NVIDIA, AMD ou Intel). Este modulo NAO baixa nem instala nada," -ForegroundColor Yellow
            Write-Host "apenas informa o que esta instalado no seu PC." -ForegroundColor Yellow
            PauseMenu
        }

        "2" {
            Write-Host ""
            Write-Host "Drivers de Rede:" -ForegroundColor Cyan
            $drivers = (Get-DriversCriticos).Rede
            foreach ($d in $drivers) {
                Write-Host ""
                Write-Host "Dispositivo.....: $($d.DeviceName)"
                Write-Host "Fabricante......: $($d.Manufacturer)"
                Write-Host "Versao..........: $($d.DriverVersion)"
                Write-Host "Data............: $($d.DriverDate)"
            }
            if (-not $drivers) { Write-Host "Nenhum driver de rede detectado via WMI." }
            PauseMenu
        }

        "3" {
            Write-Host ""
            Write-Host "Drivers de Chipset/Sistema:" -ForegroundColor Cyan
            $drivers = (Get-DriversCriticos).Chipset
            foreach ($d in $drivers) {
                Write-Host ""
                Write-Host "Dispositivo.....: $($d.DeviceName)"
                Write-Host "Fabricante......: $($d.Manufacturer)"
                Write-Host "Versao..........: $($d.DriverVersion)"
                Write-Host "Data............: $($d.DriverDate)"
            }
            if (-not $drivers) { Write-Host "Nenhum driver de chipset detectado via WMI." }
            PauseMenu
        }

        "4" {
            Write-Host ""
            Write-Host "Todos os drivers (ordenados por data, mais antigos primeiro):" -ForegroundColor Cyan
            Write-Host ""
            Get-CimInstance Win32_PnPSignedDriver |
                Where-Object { $_.DeviceName -and $_.DriverDate } |
                Sort-Object DriverDate |
                Select-Object -First 25 DeviceName, DriverVersion, DriverDate |
                Format-Table -AutoSize
            Write-Host "Mostrando os 25 mais antigos. Drivers muito antigos (3+ anos) valem uma atualizacao." -ForegroundColor Yellow
            PauseMenu
        }

        "5" {
            Write-Host ""
            Write-Host "Verificando dispositivos com problema..." -ForegroundColor Cyan
            $problemas = Get-CimInstance Win32_PnPEntity | Where-Object { $_.ConfigManagerErrorCode -ne 0 }
            if ($problemas) {
                Write-Host ""
                Write-Host "Dispositivos com erro detectados:" -ForegroundColor Red
                $problemas | Select-Object Name, ConfigManagerErrorCode | Format-Table -AutoSize
            } else {
                Write-Host ""
                Write-Host "Nenhum dispositivo com erro encontrado. Tudo certo." -ForegroundColor Green
            }
            PauseMenu
        }

        "6" {
            $criticos = Get-DriversCriticos
            $todos = Get-CimInstance Win32_PnPSignedDriver | Where-Object { $_.DeviceName -and $_.DriverDate } | Sort-Object DriverDate
            $antigos = $todos | Select-Object -First 10
            $problemas = Get-CimInstance Win32_PnPEntity | Where-Object { $_.ConfigManagerErrorCode -ne 0 }

            $arquivo = "$pastaRelatorios\Drivers_Report_$(Get-Date -Format 'ddMMyyyy_HHmmss').txt"

            $linhasGPU = $criticos.GPU | ForEach-Object { "  - $($_.DeviceName) | v$($_.DriverVersion) | $($_.DriverDate)" }
            $linhasRede = $criticos.Rede | ForEach-Object { "  - $($_.DeviceName) | v$($_.DriverVersion) | $($_.DriverDate)" }
            $linhasAntigos = $antigos | ForEach-Object { "  - $($_.DeviceName) | v$($_.DriverVersion) | $($_.DriverDate)" }
            $linhasProblemas = if ($problemas) { $problemas | ForEach-Object { "  - $($_.Name) [Erro $($_.ConfigManagerErrorCode)]" } } else { @("  Nenhum problema detectado.") }

            @"
==============================
MIX OTIMIZACOES DRIVERS REPORT
$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
==============================

DRIVERS DE GPU:
$($linhasGPU -join "`n")

DRIVERS DE REDE:
$($linhasRede -join "`n")

10 DRIVERS MAIS ANTIGOS DO SISTEMA:
$($linhasAntigos -join "`n")

DISPOSITIVOS COM PROBLEMA:
$($linhasProblemas -join "`n")

Este relatorio nao baixa nem instala drivers. Consulte o fabricante
do hardware para obter as versoes mais recentes.
"@ | Out-File $arquivo -Encoding UTF8

            Write-Host ""
            Write-Host "Relatorio salvo em: $arquivo" -ForegroundColor Green
            PauseMenu
        }

        "0" {
            Write-Host ""
            Write-Host "Voltando ao menu principal..." -ForegroundColor Cyan
            Start-Sleep -Milliseconds 600
            break
        }

        default { PauseMenu }
    }
}