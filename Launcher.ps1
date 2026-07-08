#Requires -Version 5.1
<#
.SYNOPSIS
    Mix Otimizacoes - Launcher Principal
.DESCRIPTION
    Launcher com todos os modulos categorizados, banner colorido vivo,
    criacao de Ponto de Restauracao do Windows e submenu avancado
    de Remocao de Telemetria (Safe / Aggressive / Restaurar).
#>

# ============================================================
#  CONFIGURACAO DE CAMINHOS
# ============================================================

$ModulesPath = Join-Path $PSScriptRoot "Modules"

if (-not (Test-Path $ModulesPath)) {
    New-Item -Path $ModulesPath -ItemType Directory -Force | Out-Null
}

$TelemetryModule = Join-Path $ModulesPath "28-Remove-WindowsTelemetry.ps1"

# ============================================================
#  CORES PADRAO DO LAUNCHER (paleta viva)
# ============================================================

$CorTitulo    = "Magenta"
$CorBorda     = "Cyan"
$CorOpcao     = "White"
$CorNumero    = "Yellow"
$CorDestaque  = "Green"
$CorErro      = "Red"
$CorSucesso   = "Green"
$CorAviso     = "Yellow"
$CorCategoria = "Gray"

# Cor de destaque propria de cada categoria (deixa cada tela com uma "cara" diferente)
$CorDiagnostico  = "Cyan"
$CorPerformance  = "Green"
$CorRede         = "Blue"
$CorPrivacidade  = "Magenta"
$CorVisual       = "Yellow"
$CorSeguranca    = "Red"
$CorApps         = "DarkYellow"
$CorGaming       = "DarkMagenta"
$CorServicos     = "DarkCyan"

# ============================================================
#  CHECAGEM DE ADMINISTRADOR
# ============================================================

function Test-IsAdmin {
    return ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Write-Host ""
    Write-Host "Este launcher precisa ser executado como Administrador." -ForegroundColor $CorErro
    Write-Host "Feche esta janela e escolha 'Executar como Administrador'." -ForegroundColor $CorAviso
    Write-Host ""
    Read-Host "Pressione ENTER para fechar"
    exit
}

# ============================================================
#  CARREGAMENTO DO MODULO DE TELEMETRIA (dot-source, funcoes avancadas)
# ============================================================

if (Test-Path $TelemetryModule) {
    . $TelemetryModule
} else {
    Write-Host "AVISO: modulo de Telemetria nao encontrado em: $TelemetryModule" -ForegroundColor $CorAviso
}

# ============================================================
#  BANNER / LOGO COLORIDO (cores vivas, arco-iris)
# ============================================================

function Show-Banner {
    Write-Host ""
    Write-Host "  ███╗   ███╗██╗██╗  ██╗" -ForegroundColor Magenta
    Write-Host "  ████╗ ████║██║╚██╗██╔╝" -ForegroundColor Red
    Write-Host "  ██╔████╔██║██║ ╚███╔╝ " -ForegroundColor Yellow
    Write-Host "  ██║╚██╔╝██║██║ ██╔██╗ " -ForegroundColor Green
    Write-Host "  ██║ ╚═╝ ██║██║██╔╝ ██╗" -ForegroundColor Cyan
    Write-Host "  ╚═╝     ╚═╝╚═╝╚═╝  ╚═╝" -ForegroundColor Blue
    Write-Host "        O T I M I Z A C O E S" -ForegroundColor $CorTitulo
    Write-Host ""
}

function Show-Borda {
    param([string]$Texto, [string]$Cor = $CorTitulo)
    $largura = 56
    Write-Host ("╔" + ("═" * $largura) + "╗") -ForegroundColor $Cor
    $espacoEsq = [math]::Floor(($largura - $Texto.Length) / 2)
    $espacoDir = $largura - $Texto.Length - $espacoEsq
    Write-Host ("║" + (" " * $espacoEsq) + $Texto + (" " * $espacoDir) + "║") -ForegroundColor $Cor
    Write-Host ("╚" + ("═" * $largura) + "╝") -ForegroundColor $Cor
}

function Show-Item {
    param([string]$Numero, [string]$Texto, [string]$Obs = "", [string]$CorNum = $CorNumero)
    Write-Host "   [" -NoNewline -ForegroundColor DarkGray
    Write-Host $Numero -NoNewline -ForegroundColor $CorNum
    Write-Host "] $Texto" -NoNewline -ForegroundColor $CorOpcao
    if ($Obs -ne "") {
        Write-Host "  $Obs" -ForegroundColor $CorCategoria
    } else {
        Write-Host ""
    }
}

# ============================================================
#  EXECUCAO GENERICA DE MODULO
# ============================================================

function Invoke-Modulo {
    param([string]$NomeArquivo, [string]$NomeExibicao)

    $caminho = Join-Path $ModulesPath $NomeArquivo
    Write-Host ""
    if (Test-Path $caminho) {
        Write-Host ">> Executando: $NomeExibicao" -ForegroundColor $CorDestaque
        Write-Host ""
        & $caminho
    } else {
        Write-Host "Modulo nao encontrado: $caminho" -ForegroundColor $CorErro
        Write-Host "Verifique se o arquivo esta na pasta Modules." -ForegroundColor $CorAviso
    }
    Write-Host ""
    Read-Host "Pressione ENTER para voltar"
}

# ============================================================
#  PONTO DE RESTAURACAO DO WINDOWS
# ============================================================

function New-MixRestorePoint {
    Clear-Host
    Show-Banner
    Show-Borda "CRIAR PONTO DE RESTAURACAO" $CorSeguranca
    Write-Host ""
    Write-Host "Isso cria um ponto de restauracao do Windows ANTES de aplicar" -ForegroundColor $CorOpcao
    Write-Host "otimizacoes, para voce poder desfazer tudo caso algo de errado." -ForegroundColor $CorOpcao
    Write-Host ""

    $confirmar = Read-Host "Deseja criar o ponto de restauracao agora? (S/N)"
    if ($confirmar -ne "S" -and $confirmar -ne "s") {
        Write-Host "Cancelado." -ForegroundColor $CorAviso
        Start-Sleep -Seconds 1
        return
    }

    try {
        Write-Host ""
        Write-Host "Ativando protecao de restauracao no disco do sistema..." -ForegroundColor $CorOpcao
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue

        $freqPath = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\SystemRestore"
        $freqName = "SystemRestorePointCreationFrequency"

        $valorOriginal = $null
        $existiaAntes = $false
        $chaveExistente = Get-ItemProperty -Path $freqPath -Name $freqName -ErrorAction SilentlyContinue
        if ($chaveExistente) {
            $valorOriginal = $chaveExistente.$freqName
            $existiaAntes = $true
        }

        if (-not (Test-Path $freqPath)) {
            New-Item -Path $freqPath -Force | Out-Null
        }
        New-ItemProperty -Path $freqPath -Name $freqName -Value 0 -PropertyType DWord -Force | Out-Null

        Write-Host "Criando ponto de restauracao (isso pode levar alguns segundos)..." -ForegroundColor $CorOpcao
        Checkpoint-Computer -Description "Mix Otimizacoes - Antes das otimizacoes" -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop

        if ($existiaAntes) {
            Set-ItemProperty -Path $freqPath -Name $freqName -Value $valorOriginal -ErrorAction SilentlyContinue
        } else {
            Remove-ItemProperty -Path $freqPath -Name $freqName -ErrorAction SilentlyContinue
        }

        Write-Host ""
        Write-Host "Ponto de restauracao criado com sucesso!" -ForegroundColor $CorSucesso
        Write-Host "Para restaurar depois: Painel de Controle > Recuperacao > Abrir Restauracao do Sistema." -ForegroundColor $CorCategoria
    }
    catch {
        Write-Host ""
        Write-Host "Nao foi possivel criar o ponto de restauracao." -ForegroundColor $CorErro
        Write-Host "Detalhes: $_" -ForegroundColor $CorCategoria
        Write-Host "Dica: confira se a Protecao do Sistema esta habilitada para o disco C:." -ForegroundColor $CorAviso
    }

    Write-Host ""
    Read-Host "Pressione ENTER para voltar ao menu"
}

# ============================================================
#  SUBMENU: DIAGNOSTICO E SISTEMA
# ============================================================

function Show-DiagnosticoMenu {
    Clear-Host
    Show-Banner
    Show-Borda "DIAGNOSTICO E SISTEMA" $CorDiagnostico
    Write-Host ""
    Show-Item "1" "Diagnostico Geral" "" $CorDiagnostico
    Show-Item "2" "Perfil de Hardware" "" $CorDiagnostico
    Show-Item "3" "Checagem de Drivers" "" $CorDiagnostico
    Show-Item "4" "Pontuacao do Sistema (SystemScore)" "" $CorDiagnostico
    Show-Item "0" "Voltar" "" $CorDiagnostico
    Write-Host ""
    $op = Read-Host "Escolha uma opcao"

    switch ($op) {
        "1" { Invoke-Modulo "01-Diagnostic.ps1" "Diagnostico Geral"; Show-DiagnosticoMenu }
        "2" { Invoke-Modulo "05-HardwareProfile.ps1" "Perfil de Hardware"; Show-DiagnosticoMenu }
        "3" { Invoke-Modulo "07-DriversCheck.ps1" "Checagem de Drivers"; Show-DiagnosticoMenu }
        "4" { Invoke-Modulo "15-SystemScore.ps1" "Pontuacao do Sistema"; Show-DiagnosticoMenu }
        "0" { return }
        default { Write-Host "Opcao invalida." -ForegroundColor $CorErro; Start-Sleep -Seconds 1; Show-DiagnosticoMenu }
    }
}

# ============================================================
#  SUBMENU: PERFORMANCE E OTIMIZACAO
# ============================================================

function Show-PerformanceMenu {
    Clear-Host
    Show-Banner
    Show-Borda "PERFORMANCE E OTIMIZACAO" $CorPerformance
    Write-Host ""
    Show-Item "1" "Otimizar Memoria (RAM)" "" $CorPerformance
    Show-Item "2" "Game Boost" "" $CorPerformance
    Show-Item "3" "Otimizador de Disco" "" $CorPerformance
    Show-Item "4" "Gerenciar Startup" "" $CorPerformance
    Show-Item "5" "Plano de Energia" "" $CorPerformance
    Show-Item "6" "Full Suite (tudo de uma vez)" "" $CorPerformance
    Show-Item "7" "Low Latency" "" $CorPerformance
    Show-Item "8" "Input Lag / Timer Resolution" "" $CorPerformance
    Show-Item "9" "Otimizador de GPU" "" $CorPerformance
    Show-Item "0" "Voltar" "" $CorPerformance
    Write-Host ""
    $op = Read-Host "Escolha uma opcao"

    switch ($op) {
        "1" { Invoke-Modulo "02-Memory.ps1" "Otimizar Memoria"; Show-PerformanceMenu }
        "2" { Invoke-Modulo "06-GameBoost.ps1" "Game Boost"; Show-PerformanceMenu }
        "3" { Invoke-Modulo "11-DiskOptimizer.ps1" "Otimizador de Disco"; Show-PerformanceMenu }
        "4" { Invoke-Modulo "12-Startup.ps1" "Gerenciar Startup"; Show-PerformanceMenu }
        "5" { Invoke-Modulo "13-PowerPlan.ps1" "Plano de Energia"; Show-PerformanceMenu }
        "6" { Invoke-Modulo "14-FullSuite.ps1" "Full Suite"; Show-PerformanceMenu }
        "7" { Invoke-Modulo "16-LowLatency.ps1" "Low Latency"; Show-PerformanceMenu }
        "8" { Invoke-Modulo "18-InputLagTimerRes.ps1" "Input Lag / Timer Resolution"; Show-PerformanceMenu }
        "9" { Invoke-Modulo "19-GPUOptimizer.ps1" "Otimizador de GPU"; Show-PerformanceMenu }
        "0" { return }
        default { Write-Host "Opcao invalida." -ForegroundColor $CorErro; Start-Sleep -Seconds 1; Show-PerformanceMenu }
    }
}

# ============================================================
#  SUBMENU: REDE
# ============================================================

function Show-RedeMenu {
    Clear-Host
    Show-Banner
    Show-Borda "REDE" $CorRede
    Write-Host ""
    Show-Item "1" "Otimizar Rede" "" $CorRede
    Show-Item "2" "Rede para Jogos (NetworkGaming)" "" $CorRede
    Show-Item "0" "Voltar" "" $CorRede
    Write-Host ""
    $op = Read-Host "Escolha uma opcao"

    switch ($op) {
        "1" { Invoke-Modulo "03-Network.ps1" "Otimizar Rede"; Show-RedeMenu }
        "2" { Invoke-Modulo "09-NetworkGaming.ps1" "Rede para Jogos"; Show-RedeMenu }
        "0" { return }
        default { Write-Host "Opcao invalida." -ForegroundColor $CorErro; Start-Sleep -Seconds 1; Show-RedeMenu }
    }
}

# ============================================================
#  SUBMENU: PRIVACIDADE E DEBLOAT
# ============================================================

function Show-PrivacidadeMenu {
    Clear-Host
    Show-Banner
    Show-Borda "PRIVACIDADE E DEBLOAT" $CorPrivacidade
    Write-Host ""
    Show-Item "1" "Limpeza (Cleaner)" "" $CorPrivacidade
    Show-Item "2" "Ajustes de Privacidade" "" $CorPrivacidade
    Show-Item "3" "Debloat Extremo" "" $CorPrivacidade
    Show-Item "4" "Remocao de Telemetria" "(Safe / Aggressive / Restaurar)" $CorPrivacidade
    Show-Item "0" "Voltar" "" $CorPrivacidade
    Write-Host ""
    $op = Read-Host "Escolha uma opcao"

    switch ($op) {
        "1" { Invoke-Modulo "04-Cleaner.ps1" "Limpeza"; Show-PrivacidadeMenu }
        "2" { Invoke-Modulo "08-PrivacyTweaks.ps1" "Ajustes de Privacidade"; Show-PrivacidadeMenu }
        "3" { Invoke-Modulo "20-ExtremeDebloat.ps1" "Debloat Extremo"; Show-PrivacidadeMenu }
        "4" { Show-TelemetryMenu; Show-PrivacidadeMenu }
        "0" { return }
        default { Write-Host "Opcao invalida." -ForegroundColor $CorErro; Start-Sleep -Seconds 1; Show-PrivacidadeMenu }
    }
}

# ============================================================
#  SUBMENU: TELEMETRIA (avancado, usa as funcoes do modulo 28)
# ============================================================

function Show-TelemetryMenu {
    Clear-Host
    Show-Banner
    Show-Borda "REMOCAO DE TELEMETRIA" $CorPrivacidade
    Write-Host ""
    Show-Item "1" "Modo Safe" "(recomendado)" $CorPrivacidade
    Show-Item "2" "Modo Aggressive" "(mais agressivo, ainda seguro)" $CorPrivacidade
    Show-Item "3" "Restaurar ultimo backup" "" $CorPrivacidade
    Show-Item "0" "Voltar" "" $CorPrivacidade
    Write-Host ""
    $opcao = Read-Host "Escolha uma opcao"

    switch ($opcao) {
        "1" {
            Invoke-MixTelemetryOptimization -Mode Safe
            Write-Host ""; Read-Host "Pressione ENTER para voltar"
            Show-TelemetryMenu
        }
        "2" {
            Invoke-MixTelemetryOptimization -Mode Aggressive
            Write-Host ""; Read-Host "Pressione ENTER para voltar"
            Show-TelemetryMenu
        }
        "3" {
            Invoke-MixTelemetryOptimization -Restore
            Write-Host ""; Read-Host "Pressione ENTER para voltar"
            Show-TelemetryMenu
        }
        "0" { return }
        default { Write-Host "Opcao invalida." -ForegroundColor $CorErro; Start-Sleep -Seconds 1; Show-TelemetryMenu }
    }
}

# ============================================================
#  SUBMENU: VISUAL
# ============================================================

function Show-VisualMenu {
    Clear-Host
    Show-Banner
    Show-Borda "VISUAL" $CorVisual
    Write-Host ""
    Show-Item "1" "Ajustes Visuais (VisualTweaks)" "" $CorVisual
    Show-Item "0" "Voltar" "" $CorVisual
    Write-Host ""
    $op = Read-Host "Escolha uma opcao"

    switch ($op) {
        "1" { Invoke-Modulo "10-VisualTweaks.ps1" "Ajustes Visuais"; Show-VisualMenu }
        "0" { return }
        default { Write-Host "Opcao invalida." -ForegroundColor $CorErro; Start-Sleep -Seconds 1; Show-VisualMenu }
    }
}

# ============================================================
#  SUBMENU: SEGURANCA
# ============================================================

function Show-SegurancaMenu {
    Clear-Host
    Show-Banner
    Show-Borda "SEGURANCA" $CorSeguranca
    Write-Host ""
    Show-Item "1" "Threat Scanner" "" $CorSeguranca
    Show-Item "0" "Voltar" "" $CorSeguranca
    Write-Host ""
    $op = Read-Host "Escolha uma opcao"

    switch ($op) {
        "1" { Invoke-Modulo "24-ThreatScanner.ps1" "Threat Scanner"; Show-SegurancaMenu }
        "0" { return }
        default { Write-Host "Opcao invalida." -ForegroundColor $CorErro; Start-Sleep -Seconds 1; Show-SegurancaMenu }
    }
}

# ============================================================
#  SUBMENU: APPS E INSTALADORES
# ============================================================

function Show-AppsMenu {
    Clear-Host
    Show-Banner
    Show-Borda "APPS E INSTALADORES" $CorApps
    Write-Host ""
    Show-Item "1" "Instalar Spotify" "" $CorApps
    Show-Item "2" "Instalador de Apps" "" $CorApps
    Show-Item "0" "Voltar" "" $CorApps
    Write-Host ""
    $op = Read-Host "Escolha uma opcao"

    switch ($op) {
        "1" { Invoke-Modulo "21-SpotifyInstaller.ps1" "Instalar Spotify"; Show-AppsMenu }
        "2" { Invoke-Modulo "22-AppInstaller.ps1" "Instalador de Apps"; Show-AppsMenu }
        "0" { return }
        default { Write-Host "Opcao invalida." -ForegroundColor $CorErro; Start-Sleep -Seconds 1; Show-AppsMenu }
    }
}

# ============================================================
#  SUBMENU: GAMING / FPS
# ============================================================

function Show-GamingMenu {
    Clear-Host
    Show-Banner
    Show-Borda "GAMING / FPS" $CorGaming
    Write-Host ""
    Show-Item "1" "Game Session" "" $CorGaming
    Show-Item "2" "FPS Boost" "" $CorGaming
    Show-Item "3" "FPS Advisor" "" $CorGaming
    Show-Item "4" "Fortnite Config" "" $CorGaming
    Show-Item "0" "Voltar" "" $CorGaming
    Write-Host ""
    $op = Read-Host "Escolha uma opcao"

    switch ($op) {
        "1" { Invoke-Modulo "23-GameSession.ps1" "Game Session"; Show-GamingMenu }
        "2" { Invoke-Modulo "25-FPSBoost.ps1" "FPS Boost"; Show-GamingMenu }
        "3" { Invoke-Modulo "26-FPSAdvisor.ps1" "FPS Advisor"; Show-GamingMenu }
        "4" { Invoke-Modulo "27-FortniteConfig.ps1" "Fortnite Config"; Show-GamingMenu }
        "0" { return }
        default { Write-Host "Opcao invalida." -ForegroundColor $CorErro; Start-Sleep -Seconds 1; Show-GamingMenu }
    }
}

# ============================================================
#  SUBMENU: SERVICOS MANUAIS
# ============================================================

function Show-ServicosMenu {
    Clear-Host
    Show-Banner
    Show-Borda "SERVICOS MANUAIS" $CorServicos
    Write-Host ""
    Show-Item "1" "Gerenciar Servicos Manualmente" "" $CorServicos
    Show-Item "0" "Voltar" "" $CorServicos
    Write-Host ""
    $op = Read-Host "Escolha uma opcao"

    switch ($op) {
        "1" { Invoke-Modulo "17-ServicesManual.ps1" "Servicos Manuais"; Show-ServicosMenu }
        "0" { return }
        default { Write-Host "Opcao invalida." -ForegroundColor $CorErro; Start-Sleep -Seconds 1; Show-ServicosMenu }
    }
}

# ============================================================
#  MENU PRINCIPAL
# ============================================================

function Show-MainMenu {
    Clear-Host
    Show-Banner
    Show-Borda "MENU PRINCIPAL" $CorTitulo
    Write-Host ""
    Show-Item "1" "Diagnostico e Sistema" "" $CorDiagnostico
    Show-Item "2" "Performance e Otimizacao" "" $CorPerformance
    Show-Item "3" "Rede" "" $CorRede
    Show-Item "4" "Privacidade e Debloat" "" $CorPrivacidade
    Show-Item "5" "Visual" "" $CorVisual
    Show-Item "6" "Seguranca" "" $CorSeguranca
    Show-Item "7" "Apps e Instaladores" "" $CorApps
    Show-Item "8" "Gaming / FPS" "" $CorGaming
    Show-Item "9" "Servicos Manuais" "" $CorServicos
    Write-Host ""
    Show-Item "R" "Criar Ponto de Restauracao" "(recomendado antes de otimizar)" $CorSeguranca
    Show-Item "0" "Sair" "" "White"
    Write-Host ""
    $opcao = Read-Host "Escolha uma categoria"

    switch ($opcao) {
        "1" { Show-DiagnosticoMenu; Show-MainMenu }
        "2" { Show-PerformanceMenu; Show-MainMenu }
        "3" { Show-RedeMenu; Show-MainMenu }
        "4" { Show-PrivacidadeMenu; Show-MainMenu }
        "5" { Show-VisualMenu; Show-MainMenu }
        "6" { Show-SegurancaMenu; Show-MainMenu }
        "7" { Show-AppsMenu; Show-MainMenu }
        "8" { Show-GamingMenu; Show-MainMenu }
        "9" { Show-ServicosMenu; Show-MainMenu }
        "R" { New-MixRestorePoint; Show-MainMenu }
        "r" { New-MixRestorePoint; Show-MainMenu }
        "0" {
            Write-Host ""
            Write-Host "Ate mais!" -ForegroundColor $CorDestaque
            Start-Sleep -Seconds 1
            exit
        }
        default {
            Write-Host "Opcao invalida." -ForegroundColor $CorAviso
            Start-Sleep -Seconds 1
            Show-MainMenu
        }
    }
}

# ============================================================
#  INICIO
# ============================================================

Show-MainMenu
