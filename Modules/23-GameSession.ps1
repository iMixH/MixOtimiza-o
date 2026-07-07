# ============================================================
# MIX OTIMIZACOES - GAME SESSION MODULE
# Arquivo: 27-GameSession.ps1
# Otimiza o Windows ENQUANTO o jogo esta aberto e reverte
# tudo sozinho quando o jogo fecha. Nao toca no processo do
# jogo por dentro - so ajusta como o Windows o gerencia.
# ============================================================

Clear-Host
$Host.UI.RawUI.WindowTitle = "MIX OTIMIZACOES - GAME SESSION"
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
    $logFile = "$pastaRelatorios\GameSession_Log.txt"
    "$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') - $texto" | Out-File $logFile -Append -Encoding UTF8
}

# Servicos leves que sao seguros de pausar durante uma sessao e
# retomar depois (mesma whitelist conservadora dos outros modulos)
$ServicosParaPausar = @("SysMain", "WSearch", "DiagTrack")

function Get-ProcessosJogosAbertos {
    # Lista processos que parecem ser jogos: executaveis fora de pastas
    # de sistema/Windows, geralmente com janela e uso alto de GPU/CPU
    Get-Process | Where-Object {
        $_.MainWindowTitle -ne "" -and
        $_.Path -and
        $_.Path -notmatch "\\Windows\\|\\Microsoft\\Edge|\\Google\\Chrome|\\Mozilla Firefox|\\Discord|\\Spotify"
    } | Select-Object ProcessName, Id, Path, MainWindowTitle
}

while ($true) {

    Clear-Host
    Line
    Write-Host "             MIX OTIMIZACOES - GAME SESSION" -ForegroundColor Green
    Line
    Write-Host ""
    Write-Host "Como funciona:" -ForegroundColor Cyan
    Write-Host "1. Voce escolhe o jogo que vai abrir (ou ele detecta sozinho)"
    Write-Host "2. Enquanto o jogo estiver aberto, o Mix aplica prioridade alta"
    Write-Host "   de CPU + pausa servicos leves em segundo plano"
    Write-Host "3. Quando voce fecha o jogo, TUDO volta ao normal sozinho"
    Write-Host ""
    Write-Host "SEGURO PARA ANTI-CHEAT: nao injeta nada no jogo, nao le nem" -ForegroundColor Green
    Write-Host "escreve na memoria do processo. So ajusta prioridade de CPU" -ForegroundColor Green
    Write-Host "e servicos do Windows, igual o Gerenciador de Tarefas permite" -ForegroundColor Green
    Write-Host "fazer manualmente." -ForegroundColor Green
    Write-Host ""

    Line
    Write-Host "[1] Listar Processos com Janela Aberta (para identificar o jogo)"
    Write-Host "[2] Iniciar Sessao de Jogo (monitorar processo pelo nome)"
    Write-Host "[3] Ver Servicos que Serao Pausados Durante a Sessao"
    Write-Host "[4] Gerar Relatorio"
    Write-Host "[0] Voltar"
    Write-Host ""

    $op = Read-Host "Escolha"

    switch ($op) {

        "1" {
            Write-Host ""
            Write-Host "Processos com janela aberta no momento:" -ForegroundColor Cyan
            Write-Host ""
            $lista = Get-ProcessosJogosAbertos
            if ($lista.Count -eq 0) {
                Write-Host "Nenhum processo com janela detectado alem de apps do sistema."
            } else {
                $i = 1
                foreach ($p in $lista) {
                    Write-Host "[$i] $($p.ProcessName).exe  -  `"$($p.MainWindowTitle)`""
                    $i++
                }
            }
            Write-Host ""
            Write-Host "Anote o nome do processo (ex: 'valorant' ou 'GTA5') para usar na opcao [2]." -ForegroundColor DarkGray
            PauseMenu
        }

        "2" {
            Write-Host ""
            $nomeProcesso = Read-Host "Digite o nome do processo do jogo (sem .exe, ex: valorant, GTA5, csgo)"

            if (-not $nomeProcesso -or $nomeProcesso.Trim() -eq "") {
                Write-Host "Nome invalido." -ForegroundColor Red
                PauseMenu
                continue
            }

            Write-Host ""
            Write-Host "Aguardando o jogo '$nomeProcesso' abrir..." -ForegroundColor Cyan
            Write-Host "(abra o jogo agora normalmente pela Steam/Epic/launcher)" -ForegroundColor DarkGray
            Write-Host "Pressione CTRL+C para cancelar a espera." -ForegroundColor DarkGray
            Write-Host ""

            $processo = $null
            $tentativas = 0
            while (-not $processo -and $tentativas -lt 120) {
                $processo = Get-Process -Name $nomeProcesso -ErrorAction SilentlyContinue | Select-Object -First 1
                if (-not $processo) {
                    Start-Sleep -Seconds 2
                    $tentativas++
                }
            }

            if (-not $processo) {
                Write-Host ""
                Write-Host "Jogo nao detectado apos 4 minutos de espera. Cancelado." -ForegroundColor Yellow
                PauseMenu
                continue
            }

            Write-Host ""
            Write-Host "Jogo detectado! PID: $($processo.Id)" -ForegroundColor Green
            Log-Alteracao "Sessao iniciada para '$nomeProcesso' (PID $($processo.Id))"

            # --- Aplica prioridade alta no processo do jogo ---
            try {
                $processo.PriorityClass = "High"
                Write-Host "Prioridade de CPU do jogo ajustada para Alta." -ForegroundColor Green
                Log-Alteracao "Prioridade de '$nomeProcesso' ajustada para High"
            } catch {
                Write-Host "Nao foi possivel ajustar a prioridade (pode exigir execucao como Administrador)." -ForegroundColor Yellow
            }

            # --- Pausa servicos leves ---
            $servicosPausados = @()
            foreach ($s in $ServicosParaPausar) {
                $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
                if ($svc -and $svc.Status -eq "Running") {
                    Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
                    $servicosPausados += $s
                }
            }
            if ($servicosPausados.Count -gt 0) {
                Write-Host "Servicos pausados durante a sessao: $($servicosPausados -join ', ')" -ForegroundColor Green
                Log-Alteracao "Servicos pausados: $($servicosPausados -join ', ')"
            }

            Write-Host ""
            Write-Host "Sessao ativa. Aproveite o jogo!" -ForegroundColor Cyan
            Write-Host "Esta janela vai monitorar o jogo e reverter tudo quando voce fechar ele." -ForegroundColor DarkGray
            Write-Host ""

            # --- Monitora ate o processo fechar ---
            while (Get-Process -Id $processo.Id -ErrorAction SilentlyContinue) {
                Start-Sleep -Seconds 3
            }

            Write-Host ""
            Write-Host "Jogo fechado. Revertendo alteracoes..." -ForegroundColor Cyan

            foreach ($s in $servicosPausados) {
                Start-Service -Name $s -ErrorAction SilentlyContinue
            }
            Log-Alteracao "Sessao finalizada para '$nomeProcesso'. Servicos revertidos: $($servicosPausados -join ', ')"

            Write-Host "Servicos reativados. Tudo de volta ao normal." -ForegroundColor Green
            PauseMenu
        }

        "3" {
            Write-Host ""
            Write-Host "Servicos que serao pausados durante a sessao de jogo:" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "  - SysMain (Superfetch): pre-carrega apps na RAM, pouco util durante jogo"
            Write-Host "  - WSearch (Windows Search): indexacao de arquivos em segundo plano"
            Write-Host "  - DiagTrack (Telemetria): coleta de dados de diagnostico"
            Write-Host ""
            Write-Host "Todos voltam automaticamente ao estado normal quando o jogo fecha." -ForegroundColor Green
            Write-Host "Nenhum servico critico (rede, seguranca, Windows Update) e tocado." -ForegroundColor Green
            PauseMenu
        }

        "4" {
            $arquivo = "$pastaRelatorios\GameSession_Report_$(Get-Date -Format 'ddMMyyyy_HHmmss').txt"

            @"
==============================
MIX OTIMIZACOES GAME SESSION REPORT
$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
==============================

Este modulo ajusta prioridade de CPU do processo do jogo e pausa
servicos leves (SysMain, WSearch, DiagTrack) apenas durante a sessao,
revertendo tudo automaticamente ao fechar o jogo.

Nao injeta codigo, nao le/escreve memoria de processos, e seguro
para qualquer sistema de anti-cheat.

Consulte GameSession_Log.txt para o historico de sessoes.
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