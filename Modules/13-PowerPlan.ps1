# ============================================================
# MIX OTIMIZACOES - POWER PLAN MODULE
# Arquivo: 13-PowerPlan.ps1
# ============================================================

Clear-Host
$Host.UI.RawUI.WindowTitle = "MIX OTIMIZACOES - POWER PLAN"
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

function Log-Alteracao($texto) {
    $logFile = "$pastaRelatorios\PowerPlan_Log.txt"
    "$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') - $texto" | Out-File $logFile -Append -Encoding UTF8
}

# GUID do Ultimate Performance (oculto por padrao no Windows)
$UltimateGUID = "e9a42b02-d5df-448d-aa00-03f14749eb61"

function Get-UltimateAtivo {
    $lista = powercfg /list
    return ($lista -match $UltimateGUID)
}

while ($true) {

    Clear-Host
    Line
    Write-Host "            MIX OTIMIZACOES - POWER PLAN" -ForegroundColor Green
    Line
    Write-Host ""

    $ativo = powercfg /getactivescheme
    Write-Host "Plano Ativo Atual:"
    Write-Host "$ativo" -ForegroundColor Yellow
    Write-Host ""

    Line
    Write-Host "[1] Ativar Plano Equilibrado"
    Write-Host "[2] Ativar Plano Alto Desempenho"
    Write-Host "[3] Desbloquear e Ativar Ultimate Performance"
    Write-Host "[4] Ativar Plano Economia de Energia"
    Write-Host "[5] Listar Todos os Planos Disponiveis"
    Write-Host "[6] Ajustar Timeout de Tela/Suspensao"
    Write-Host "[7] Impedir Suspensao Automatica (uso atual)"
    Write-Host "[8] Gerar Relatorio"
    Write-Host "[0] Voltar"
    Write-Host ""

    $op = Read-Host "Escolha"

    switch ($op) {

        "1" {
            powercfg /setactive SCHEME_BALANCED
            Log-Alteracao "Plano alterado para Equilibrado"
            Write-Host ""
            Write-Host "Plano Equilibrado ativado." -ForegroundColor Green
            PauseMenu
        }

        "2" {
            powercfg /setactive SCHEME_MIN
            Log-Alteracao "Plano alterado para Alto Desempenho"
            Write-Host ""
            Write-Host "Plano Alto Desempenho ativado." -ForegroundColor Green
            PauseMenu
        }

        "3" {
            if (-not (Get-UltimateAtivo)) {
                powercfg -duplicatescheme $UltimateGUID | Out-Null
                Write-Host ""
                Write-Host "Ultimate Performance desbloqueado." -ForegroundColor Green
            }
            powercfg /setactive $UltimateGUID
            Log-Alteracao "Plano alterado para Ultimate Performance"
            Write-Host "Ultimate Performance ativado." -ForegroundColor Green
            Write-Host ""
            Write-Host "Nota: este plano prioriza desempenho maximo e pode aumentar" -ForegroundColor Yellow
            Write-Host "o consumo de energia. Ideal para desktops, nao recomendado" -ForegroundColor Yellow
            Write-Host "para notebooks rodando na bateria." -ForegroundColor Yellow
            PauseMenu
        }

        "4" {
            powercfg /setactive SCHEME_MAX
            Log-Alteracao "Plano alterado para Economia de Energia"
            Write-Host ""
            Write-Host "Plano Economia de Energia ativado." -ForegroundColor Green
            PauseMenu
        }

        "5" {
            Write-Host ""
            powercfg /list
            PauseMenu
        }

        "6" {
            Write-Host ""
            Write-Host "Configurar tempo (em minutos) para desligar tela / suspender PC." -ForegroundColor Cyan
            Write-Host "Digite 0 para nunca."
            Write-Host ""
            $tela = Read-Host "Tempo para desligar a tela (minutos)"
            $susp = Read-Host "Tempo para suspender o PC (minutos)"

            if ($tela -match "^\d+$") {
                powercfg /change monitor-timeout-ac $tela
                Log-Alteracao "Timeout de tela alterado para $tela minutos"
            }
            if ($susp -match "^\d+$") {
                powercfg /change standby-timeout-ac $susp
                Log-Alteracao "Timeout de suspensao alterado para $susp minutos"
            }
            Write-Host ""
            Write-Host "Configuracoes aplicadas." -ForegroundColor Green
            PauseMenu
        }

        "7" {
            Write-Host ""
            Write-Host "Isso vai impedir o PC de suspender enquanto esta janela ficar aberta." -ForegroundColor Yellow
            Write-Host "Util durante sessoes longas de jogo/stream. Feche esta janela para desativar." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Pressione CTRL+C para cancelar a qualquer momento." -ForegroundColor DarkGray
            Write-Host ""
            try {
                Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
                while ($true) {
                    [System.Windows.Forms.Cursor]::Position = [System.Windows.Forms.Cursor]::Position
                    Start-Sleep -Seconds 60
                }
            } catch {
                Write-Host "Recurso indisponivel neste ambiente." -ForegroundColor Red
                PauseMenu
            }
        }

        "8" {
            $arquivo = "$pastaRelatorios\PowerPlan_Report_$(Get-Date -Format 'ddMMyyyy_HHmmss').txt"
            $planos = powercfg /list

            @"
==============================
MIX OTIMIZACOES POWER PLAN REPORT
$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
==============================

PLANO ATIVO:
$ativo

PLANOS DISPONIVEIS:
$planos

Consulte PowerPlan_Log.txt para o historico de alteracoes.
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