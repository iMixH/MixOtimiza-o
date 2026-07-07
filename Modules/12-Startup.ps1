# ============================================================
# MIX OTIMIZACOES - STARTUP MODULE
# Arquivo: 12-Startup.ps1
# ============================================================

Clear-Host
$Host.UI.RawUI.WindowTitle = "MIX OTIMIZACOES - STARTUP"
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

function Log-Alteracao($texto) {
    $logFile = "$pastaRelatorios\Startup_Log.txt"
    "$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') - $texto" | Out-File $logFile -Append -Encoding UTF8
}

function Get-ProgramasStartup {
    $lista = @()

    # Itens via WMI (mais confiavel para pasta Startup e Run keys comuns)
    $wmi = Get-CimInstance Win32_StartupCommand
    foreach ($item in $wmi) {
        $lista += [PSCustomObject]@{
            Nome     = $item.Name
            Comando  = $item.Command
            Local    = $item.Location
            Origem   = "WMI"
        }
    }
    return $lista
}

while ($true) {

    Clear-Host
    Line
    Write-Host "              MIX OTIMIZACOES - STARTUP" -ForegroundColor Green
    Line
    Write-Host ""

    $programas = Get-ProgramasStartup
    Write-Host "Programas detectados na inicializacao: $($programas.Count)"
    Write-Host ""

    Line
    Write-Host "[1] Listar Programas de Inicializacao"
    Write-Host "[2] Desativar Programa Selecionado (Registro HKCU/HKLM Run)"
    Write-Host "[3] Ver Impacto Estimado no Boot"
    Write-Host "[4] Gerar Relatorio"
    Write-Host "[0] Voltar"
    Write-Host ""

    $op = Read-Host "Escolha"

    switch ($op) {

        "1" {
            Write-Host ""
            $i = 1
            foreach ($p in $programas) {
                Write-Host "[$i] $($p.Nome)" -ForegroundColor White
                Write-Host "     Local: $($p.Local)" -ForegroundColor DarkGray
                Write-Host "     Comando: $($p.Comando)" -ForegroundColor DarkGray
                Write-Host ""
                $i++
            }
            if ($programas.Count -eq 0) { Write-Host "Nenhum programa de inicializacao detectado." }
            PauseMenu
        }

        "2" {
            if ($programas.Count -eq 0) {
                Write-Host ""
                Write-Host "Nenhum programa para desativar." -ForegroundColor Yellow
                PauseMenu
                continue
            }

            Write-Host ""
            $i = 1
            foreach ($p in $programas) {
                Write-Host "[$i] $($p.Nome) ($($p.Local))"
                $i++
            }
            Write-Host ""
            $escolha = Read-Host "Digite o numero do programa a desativar"

            if ($escolha -match "^\d+$" -and [int]$escolha -ge 1 -and [int]$escolha -le $programas.Count) {
                $alvo = $programas[[int]$escolha - 1]

                if (Confirmar "Isso vai remover '$($alvo.Nome)' da inicializacao. O programa continua instalado, so nao abre mais sozinho.") {
                    $sucesso = $false

                    # Tenta remover das chaves Run mais comuns (HKCU e HKLM)
                    $caminhos = @(
                        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
                        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
                        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
                    )

                    foreach ($c in $caminhos) {
                        if (Test-Path $c) {
                            $props = Get-ItemProperty -Path $c -ErrorAction SilentlyContinue
                            foreach ($prop in $props.PSObject.Properties) {
                                if ($prop.Name -eq $alvo.Nome) {
                                    Remove-ItemProperty -Path $c -Name $prop.Name -ErrorAction SilentlyContinue
                                    $sucesso = $true
                                }
                            }
                        }
                    }

                    if ($sucesso) {
                        Log-Alteracao "Removido da inicializacao: $($alvo.Nome) (Comando: $($alvo.Comando))"
                        Write-Host ""
                        Write-Host "'$($alvo.Nome)' removido da inicializacao." -ForegroundColor Green
                    } else {
                        Write-Host ""
                        Write-Host "Nao foi possivel remover automaticamente." -ForegroundColor Yellow
                        Write-Host "Este item pode estar na pasta Startup ou no Agendador de Tarefas." -ForegroundColor Yellow
                        Write-Host "Abra o Gerenciador de Tarefas > Aba Inicializar para desativa-lo manualmente." -ForegroundColor Yellow
                    }
                }
            } else {
                Write-Host "Opcao invalida." -ForegroundColor Red
            }
            PauseMenu
        }

        "3" {
            Write-Host ""
            $qtd = $programas.Count
            $impacto = if ($qtd -le 3) { "Baixo" } elseif ($qtd -le 8) { "Medio" } else { "Alto" }
            $cor = if ($qtd -le 3) { "Green" } elseif ($qtd -le 8) { "Yellow" } else { "Red" }
            Write-Host "Programas na inicializacao: $qtd"
            Write-Host "Impacto estimado no tempo de boot: " -NoNewline
            Write-Host $impacto -ForegroundColor $cor
            Write-Host ""
            Write-Host "Recomendado: manter ate 5 programas essenciais na inicializacao." -ForegroundColor DarkGray
            PauseMenu
        }

        "4" {
            $arquivo = "$pastaRelatorios\Startup_Report_$(Get-Date -Format 'ddMMyyyy_HHmmss').txt"
            $linhas = $programas | ForEach-Object { "  - $($_.Nome) [$($_.Local)] -> $($_.Comando)" }

            @"
==============================
MIX OTIMIZACOES STARTUP REPORT
$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
==============================

TOTAL DE PROGRAMAS: $($programas.Count)

PROGRAMAS DETECTADOS:
$($linhas -join "`n")

Consulte Startup_Log.txt para o historico de itens removidos.
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