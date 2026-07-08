# ============================================================
# MIX OTIMIZACOES - LAUNCHER PRINCIPAL
# ============================================================

$Host.UI.RawUI.WindowTitle = "MIX OTIMIZACOES"
$ErrorActionPreference = "SilentlyContinue"
Clear-Host

if ($PSScriptRoot) {
    $base = $PSScriptRoot
} else {
    $base = Split-Path -Parent ([System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName)
}
$modulos = Join-Path $base "Modules"

function Show-Logo {
    Write-Host ""
    Write-Host "     ============================================" -ForegroundColor DarkCyan
    Write-Host "     |                                          |" -ForegroundColor DarkCyan
    Write-Host "     |   M   M   III    X   X                   |" -ForegroundColor Cyan
    Write-Host "     |   MM MM    I      X X                    |" -ForegroundColor Cyan
    Write-Host "     |   M M M    I       X                     |" -ForegroundColor Cyan
    Write-Host "     |   M   M    I      X X                    |" -ForegroundColor Cyan
    Write-Host "     |   M   M   III    X   X                   |" -ForegroundColor Cyan
    Write-Host "     |                                          |" -ForegroundColor DarkCyan
    Write-Host "     |          O T I M I Z A D O R              |" -ForegroundColor White
    Write-Host "     |                                          |" -ForegroundColor DarkCyan
    Write-Host "     ============================================" -ForegroundColor DarkCyan
    Write-Host ""
}

function Line {
    Write-Host "  ------------------------------------------------------------" -ForegroundColor DarkGray
}

function SectionHeader($titulo, $cor) {
    Write-Host ""
    Write-Host "  > $titulo" -ForegroundColor $cor
    Line
}

function AbrirModulo($arquivo, $nomeExibicao) {
    $caminhoCompleto = Join-Path $modulos $arquivo
    if (Test-Path $caminhoCompleto) {
        Write-Host ""
        Write-Host "  Abrindo: $nomeExibicao ..." -ForegroundColor Cyan
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$caminhoCompleto`"" -Wait
    } else {
        Write-Host ""
        Write-Host "  Modulo nao encontrado: $nomeExibicao" -ForegroundColor Red
        Write-Host "  Esperado em: $caminhoCompleto" -ForegroundColor DarkGray
        Write-Host ""
        Read-Host "  Pressione ENTER para voltar ao menu"
    }
}

# ------------------------------------------------------------
# Modulos organizados por categoria - batendo com os arquivos
# que voce tem salvos atualmente (01 a 26)
# ------------------------------------------------------------
$Categorias = @(

    @{
        Titulo = "DIAGNOSTICO E SISTEMA"
        Cor = "Cyan"
        Itens = @(
            @{ Op = "1";  Arquivo = "01-Diagnostic.ps1";      Nome = "Diagnostico do Sistema" }
            @{ Op = "2";  Arquivo = "02-Memory.ps1";           Nome = "Memoria RAM" }
            @{ Op = "3";  Arquivo = "03-Network.ps1";          Nome = "Rede" }
            @{ Op = "5";  Arquivo = "05-HardwareProfile.ps1";  Nome = "Perfil de Hardware" }
            @{ Op = "15"; Arquivo = "15-SystemScore.ps1";      Nome = "Nota de Saude do Sistema" }
        )
    },

    @{
        Titulo = "LIMPEZA E MANUTENCAO"
        Cor = "Green"
        Itens = @(
            @{ Op = "4";  Arquivo = "04-Cleaner.ps1";          Nome = "Limpeza de Arquivos" }
            @{ Op = "11"; Arquivo = "11-DiskOptimizer.ps1";     Nome = "Otimizador de Disco" }
            @{ Op = "12"; Arquivo = "12-Startup.ps1";          Nome = "Gerenciador de Inicializacao" }
            @{ Op = "20"; Arquivo = "20-ExtremeDebloat.ps1";   Nome = "Extreme Debloat (Zona Exclusiva)" }
        )
    },

    @{
        Titulo = "PERFORMANCE PARA JOGOS"
        Cor = "Yellow"
        Itens = @(
            @{ Op = "6";  Arquivo = "06-GameBoost.ps1";        Nome = "Game Boost" }
            @{ Op = "9";  Arquivo = "09-NetworkGaming.ps1";     Nome = "Rede para Jogos" }
            @{ Op = "16"; Arquivo = "16-LowLatency.ps1";        Nome = "Low Latency Mode" }
            @{ Op = "17"; Arquivo = "17-ServicesManual.ps1";    Nome = "Services Manual Mode" }
            @{ Op = "18"; Arquivo = "18-InputLagTimerRes.ps1"; Nome = "Input Lag + Timer Resolution" }
            @{ Op = "19"; Arquivo = "19-GPUOptimizer.ps1";      Nome = "GPU Optimizer (NVIDIA/AMD)" }
            @{ Op = "23"; Arquivo = "23-GameSession.ps1";       Nome = "Game Session (Auto)" }
            @{ Op = "25"; Arquivo = "25-FPSBoost.ps1";          Nome = "FPS Boost + Modo Clean" }
            @{ Op = "26"; Arquivo = "26-FPSAdvisor.ps1";        Nome = "FPS Advisor (Config por Jogo)" }
            @{ Op = "27"; Arquivo = "27-FortniteConfig.ps1";        Nome = "Fortnite Config Graphics(BETA)" }
        )
    },

    @{
        Titulo = "ENERGIA E VISUAL"
        Cor = "Magenta"
        Itens = @(
            @{ Op = "10"; Arquivo = "10-VisualTweaks.ps1";      Nome = "Ajustes Visuais" }
            @{ Op = "13"; Arquivo = "13-PowerPlan.ps1";         Nome = "Plano de Energia" }
        )
    },

    @{
        Titulo = "PRIVACIDADE E SEGURANCA"
        Cor = "Red"
        Itens = @(
            @{ Op = "8";  Arquivo = "08-PrivacyTweaks.ps1";     Nome = "Ajustes de Privacidade" }
            @{ Op = "24"; Arquivo = "24-ThreatScanner.ps1";     Nome = "Threat Scanner (Indicadores)" }
            @{ Op = "29"; Arquivo = "28-Remove-WindowsTelemetry.ps1";     Nome = "Remove Win Telemetry (Removedor de telemtria)" }
        )
    },

    @{
        Titulo = "APLICATIVOS E DRIVERS"
        Cor = "DarkCyan"
        Itens = @(
            @{ Op = "7";  Arquivo = "07-DriversCheck.ps1";      Nome = "Verificador de Drivers" }
            @{ Op = "21"; Arquivo = "21-SpotifyInstaller.ps1";  Nome = "Spotify + Spicetify" }
            @{ Op = "22"; Arquivo = "22-AppInstaller.ps1";      Nome = "App Installer" }
        )
    },

    @{
        Titulo = "OTIMIZACAO COMPLETA"
        Cor = "White"
        Itens = @(
            @{ Op = "14"; Arquivo = "14-FullSuite.ps1";         Nome = "Otimizacao Completa (Perfil Automatico)" }
        )
    }
)

$TodosItens = @()
foreach ($cat in $Categorias) { $TodosItens += $cat.Itens }

while ($true) {
    Clear-Host
    Show-Logo

    foreach ($cat in $Categorias) {
        SectionHeader $cat.Titulo $cat.Cor
        foreach ($item in $cat.Itens) {
            $num = $item.Op.PadLeft(2)
            Write-Host "    [$num] $($item.Nome)"
        }
    }

    Write-Host ""
    Line
    Write-Host "    [ 0] Sair" -ForegroundColor Red
    Line
    Write-Host ""
    $op = Read-Host "  Escolha uma opcao"

    if ($op -eq "0") {
        Clear-Host
        Show-Logo
        Write-Host "  Obrigado por usar o Mix Otimizador!" -ForegroundColor Cyan
        Write-Host ""
        Start-Sleep -Seconds 1
        exit
    }

    $selecionado = $TodosItens | Where-Object { $_.Op -eq $op }

    if ($selecionado) {
        AbrirModulo $selecionado.Arquivo $selecionado.Nome
    } else {
        Write-Host ""
        Write-Host "  Opcao invalida." -ForegroundColor Red
        Start-Sleep -Seconds 1
    }
}