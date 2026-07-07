# ============================================================
# MIX OTIMIZACOES - GAME BOOST MODULE
# Arquivo: 06-GameBoost.ps1
# ============================================================

Clear-Host
$Host.UI.RawUI.WindowTitle = "MIX OTIMIZACOES - GAME BOOST"
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

$ServicosOpcionais = @(
    @{ Nome = "XblAuthManager";     Desc = "Xbox Live Auth Manager (login Xbox)" }
    @{ Nome = "XblGameSave";        Desc = "Xbox Live Game Save (sincronizacao de save na nuvem)" }
    @{ Nome = "XboxNetApiSvc";      Desc = "Xbox Live Networking Service" }
    @{ Nome = "XboxGipSvc";         Desc = "Xbox Accessory Management Service" }
    @{ Nome = "SysMain";            Desc = "Superfetch/SysMain (pre-carrega apps na RAM)" }
    @{ Nome = "DiagTrack";          Desc = "Telemetria e Diagnostico do Windows" }
    @{ Nome = "WSearch";            Desc = "Windows Search (indexacao de arquivos)" }
    @{ Nome = "Fax";                Desc = "Servico de Fax" }
    @{ Nome = "PrintNotify";        Desc = "Notificacoes de Impressora" }
    @{ Nome = "RemoteRegistry";     Desc = "Registro Remoto" }
    @{ Nome = "MapsBroker";         Desc = "Downloaded Maps Manager" }
    @{ Nome = "RetailDemo";         Desc = "Retail Demo Service" }
)

function Get-ServicosDetectados {
    $detectados = @()
    foreach ($s in $ServicosOpcionais) {
        $svc = Get-Service -Name $s.Nome -ErrorAction SilentlyContinue
        if ($svc) {
            $detectados += [PSCustomObject]@{ Nome = $s.Nome; Desc = $s.Desc; Status = $svc.Status }
        }
    }
    return $detectados
}

function Log-Alteracao($texto) {
    $logFile = "$pastaRelatorios\GameBoost_Log.txt"
    "$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') - $texto" | Out-File $logFile -Append -Encoding UTF8
}

while ($true) {

    Clear-Host
    Line
    Write-Host "              MIX OTIMIZACOES - GAME BOOST" -ForegroundColor Green
    Line
    Write-Host ""

    $cpu = Get-CimInstance Win32_Processor
    $ram = Get-CimInstance Win32_ComputerSystem
    $totalRam = [math]::Round($ram.TotalPhysicalMemory / 1GB, 2)
    $planoAtual = (powercfg /getactivescheme)

    Write-Host "CPU..............: $($cpu.Name)"
    Write-Host "RAM..............: $totalRam GB"
    Write-Host "Plano de Energia.: $planoAtual"
    Write-Host ""

    Line
    Write-Host "[1] Ver Servicos Nao-Essenciais Detectados"
    Write-Host "[2] Desativar Servicos Selecionados"
    Write-Host "[3] Reativar Todos os Servicos (Reverter)"
    Write-Host "[4] Ativar Plano de Energia Alto Desempenho"
    Write-Host "[5] Ativar Game Mode"
    Write-Host "[6] Desativar Efeitos Visuais (deixar PC mais leve)"
    Write-Host "[7] Aplicar Otimizacao Completa para Jogos"
    Write-Host "[8] Gerar Relatorio"
    Write-Host "[0] Voltar"
    Write-Host ""

    $op = Read-Host "Escolha"

    switch ($op) {

        "1" {
            Write-Host ""
            Write-Host "Servicos nao-essenciais detectados no seu PC:" -ForegroundColor Cyan
            Write-Host ""
            $lista = Get-ServicosDetectados
            if ($lista.Count -eq 0) {
                Write-Host "Nenhum desses servicos foi encontrado no sistema."
            } else {
                $i = 1
                foreach ($item in $lista) {
                    $cor = if ($item.Status -eq "Running") { "Yellow" } else { "DarkGray" }
                    Write-Host "[$i] $($item.Nome) - $($item.Desc) [$($item.Status)]" -ForegroundColor $cor
                    $i++
                }
            }
            PauseMenu
        }

        "2" {
            $lista = Get-ServicosDetectados | Where-Object { $_.Status -eq "Running" }
            if ($lista.Count -eq 0) {
                Write-Host ""
                Write-Host "Nenhum servico opcional ativo para desativar."
                PauseMenu
                continue
            }

            Write-Host ""
            Write-Host "Servicos ativos que podem ser desativados:" -ForegroundColor Cyan
            $i = 1
            foreach ($item in $lista) {
                Write-Host "[$i] $($item.Nome) - $($item.Desc)"
                $i++
            }
            Write-Host ""
            Write-Host "Digite os numeros separados por virgula (ex: 1,3,5) ou 'todos' para selecionar tudo."
            $escolha = Read-Host "Selecao"

            if ($escolha -eq "todos") {
                $selecionados = $lista
            } else {
                $indices = $escolha -split "," | ForEach-Object { $_.Trim() }
                $selecionados = @()
                foreach ($idx in $indices) {
                    if ($idx -match "^\d+$" -and [int]$idx -ge 1 -and [int]$idx -le $lista.Count) {
                        $selecionados += $lista[[int]$idx - 1]
                    }
                }
            }

            if ($selecionados.Count -eq 0) {
                Write-Host ""
                Write-Host "Nenhum item valido selecionado." -ForegroundColor Red
                PauseMenu
                continue
            }

            if (Confirmar "Isso vai parar e desativar $($selecionados.Count) servico(s). Use a opcao [3] para reverter depois.") {
                foreach ($item in $selecionados) {
                    Stop-Service -Name $item.Nome -Force -ErrorAction SilentlyContinue
                    Set-Service -Name $item.Nome -StartupType Disabled -ErrorAction SilentlyContinue
                    Log-Alteracao "Servico desativado: $($item.Nome)"
                    Write-Host "Desativado: $($item.Nome)" -ForegroundColor Green
                }
            }
            PauseMenu
        }

        "3" {
            if (Confirmar "Isso vai reativar (StartupType Manual) todos os servicos opcionais listados nesta ferramenta.") {
                foreach ($s in $ServicosOpcionais) {
                    $svc = Get-Service -Name $s.Nome -ErrorAction SilentlyContinue
                    if ($svc) {
                        Set-Service -Name $s.Nome -StartupType Manual -ErrorAction SilentlyContinue
                        Log-Alteracao "Servico revertido para Manual: $($s.Nome)"
                    }
                }
                Write-Host ""
                Write-Host "Servicos revertidos para inicializacao Manual." -ForegroundColor Green
                Write-Host "Reinicie o PC para que voltem a rodar normalmente quando necessarios."
            }
            PauseMenu
        }

        "4" {
            powercfg /setactive SCHEME_MIN
            Log-Alteracao "Plano de energia alterado para Alto Desempenho"
            Write-Host ""
            Write-Host "Plano de Alto Desempenho ativado." -ForegroundColor Green
            PauseMenu
        }

        "5" {
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 1 -ErrorAction SilentlyContinue
            Log-Alteracao "Game Mode ativado"
            Write-Host ""
            Write-Host "Game Mode ativado." -ForegroundColor Green
            PauseMenu
        }

        "6" {
            if (Confirmar "Isso vai desativar animacoes e transparencias visuais do Windows para ganhar performance.") {
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -ErrorAction SilentlyContinue
                Log-Alteracao "Efeitos visuais reduzidos (modo desempenho)"
                Write-Host ""
                Write-Host "Efeitos visuais reduzidos. Pode ser necessario relogar para ver efeito completo." -ForegroundColor Green
            }
            PauseMenu
        }

        "7" {
            if (Confirmar "Isso vai aplicar: desativar servicos opcionais ativos, Alto Desempenho, Game Mode e reduzir efeitos visuais.") {
                Write-Host ""
                Write-Host "Aplicando otimizacao completa..." -ForegroundColor Cyan

                $lista = Get-ServicosDetectados | Where-Object { $_.Status -eq "Running" }
                foreach ($item in $lista) {
                    Stop-Service -Name $item.Nome -Force -ErrorAction SilentlyContinue
                    Set-Service -Name $item.Nome -StartupType Disabled -ErrorAction SilentlyContinue
                    Log-Alteracao "Servico desativado: $($item.Nome)"
                }

                powercfg /setactive SCHEME_MIN
                Log-Alteracao "Plano de energia alterado para Alto Desempenho"

                Set-ItemProperty -Path "HKCU:\Software\Microsoft\GameBar" -Name "AutoGameModeEnabled" -Value 1 -ErrorAction SilentlyContinue
                Log-Alteracao "Game Mode ativado"

                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -ErrorAction SilentlyContinue
                Log-Alteracao "Efeitos visuais reduzidos"

                Write-Host ""
                Write-Host "Otimizacao completa aplicada!" -ForegroundColor Green
                Write-Host "$($lista.Count) servico(s) desativado(s)." -ForegroundColor Green
                Write-Host "Use a opcao [3] a qualquer momento para reverter os servicos."
            }
            PauseMenu
        }

        "8" {
            $lista = Get-ServicosDetectados
            $arquivo = "$pastaRelatorios\GameBoost_Report_$(Get-Date -Format 'ddMMyyyy_HHmmss').txt"
            $linhasServicos = $lista | ForEach-Object { "  - $($_.Nome) [$($_.Status)] - $($_.Desc)" }

            @"
==============================
MIX OTIMIZACOES GAME BOOST REPORT
$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
==============================

CPU..............: $($cpu.Name)
RAM..............: $totalRam GB
Plano de Energia.: $planoAtual

SERVICOS OPCIONAIS DETECTADOS:
$($linhasServicos -join "`n")

Consulte GameBoost_Log.txt para o historico completo de alteracoes feitas.
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