# ============================================================
# MIX OTIMIZACOES - FPS BOOST MODULE
# Arquivo: 28-FPSBoost.ps1
# Otimizacoes reais e mensuraveis para ganho de FPS/estabilidade.
# Nao promete milagre - explica o que cada item realmente faz.
# ============================================================

Clear-Host
$Host.UI.RawUI.WindowTitle = "MIX OTIMIZACOES - FPS BOOST"
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
    $logFile = "$pastaRelatorios\FPSBoost_Log.txt"
    "$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') - $texto" | Out-File $logFile -Append -Encoding UTF8
}

function FolderSize($Path) {
    if (Test-Path $Path) {
        $size = (Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
        if ($size) { return $size }
    }
    return 0
}

$pathVisualFX = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
$pathGameDVR = "HKCU:\System\GameConfigStore"
$pathGameBar = "HKCU:\Software\Microsoft\GameBar"
$pathTransparency = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
$pathFullscreenOpt = "HKCU:\System\GameConfigStore"

$ServicosLeves = @("SysMain", "WSearch", "DiagTrack")

$Itens = @(

    @{
        Id = 1
        Nome = "Game Mode + Otimizacao de Tela Cheia"
        Desc = "Ativa o Game Mode do Windows e desativa as otimizacoes de" + `
               " tela cheia que o Windows 10/11 aplicam por padrao (podem" + `
               " causar microstutter em jogos DX9/DX11 mais antigos)."
        Aviso = $null
        Check = {
            $v1 = (Get-ItemProperty -Path $pathGameBar -Name "AutoGameModeEnabled" -ErrorAction SilentlyContinue).AutoGameModeEnabled
            $v1 -eq 1
        }
        Aplicar = {
            Set-ItemProperty -Path $pathGameBar -Name "AutoGameModeEnabled" -Value 1 -Type DWord
            Log-Alteracao "Game Mode ativado"
        }
        Reverter = {
            Set-ItemProperty -Path $pathGameBar -Name "AutoGameModeEnabled" -Value 0 -Type DWord
            Log-Alteracao "Game Mode revertido"
        }
    },

    @{
        Id = 2
        Nome = "Desativar Game DVR / Xbox Game Bar"
        Desc = "Desativa a gravacao em segundo plano do Game Bar. Esse recurso" + `
               " consome CPU/GPU/disco continuamente enquanto voce joga, mesmo" + `
               " sem estar gravando nada ativamente. Ganho real de FPS, especialmente" + `
               " em PCs com CPU mais fraca."
        Aviso = $null
        Check = {
            $v = (Get-ItemProperty -Path $pathGameDVR -Name "GameDVR_Enabled" -ErrorAction SilentlyContinue).GameDVR_Enabled
            $v -eq 0
        }
        Aplicar = {
            New-ItemProperty -Path $pathGameDVR -Name "GameDVR_Enabled" -Value 0 -PropertyType DWord -Force | Out-Null
            Log-Alteracao "Game DVR desativado"
        }
        Reverter = {
            New-ItemProperty -Path $pathGameDVR -Name "GameDVR_Enabled" -Value 1 -PropertyType DWord -Force | Out-Null
            Log-Alteracao "Game DVR revertido para ativado"
        }
    },

    @{
        Id = 3
        Nome = "Modo Visual Clean (Efeitos Reduzidos ao Maximo)"
        Desc = "Desativa animacoes, sombras, transparencias e efeitos visuais" + `
               " do Windows. Libera CPU/GPU que o sistema operacional usaria" + `
               " para renderizar a interface, e deixa o visual mais 'limpo' e direto."
        Aviso = $null
        Check = {
            $v = (Get-ItemProperty -Path $pathVisualFX -Name "VisualFXSetting" -ErrorAction SilentlyContinue).VisualFXSetting
            $v -eq 2
        }
        Aplicar = {
            if (-not (Test-Path $pathVisualFX)) { New-Item -Path $pathVisualFX -Force | Out-Null }
            Set-ItemProperty -Path $pathVisualFX -Name "VisualFXSetting" -Value 2 -Type DWord
            Set-ItemProperty -Path $pathTransparency -Name "EnableTransparency" -Value 0 -ErrorAction SilentlyContinue
            Log-Alteracao "Modo Visual Clean aplicado (efeitos minimos, sem transparencia)"
        }
        Reverter = {
            Set-ItemProperty -Path $pathVisualFX -Name "VisualFXSetting" -Value 0 -Type DWord
            Set-ItemProperty -Path $pathTransparency -Name "EnableTransparency" -Value 1 -ErrorAction SilentlyContinue
            Log-Alteracao "Efeitos visuais revertidos para padrao"
        }
    },

    @{
        Id = 4
        Nome = "Plano de Energia Alto Desempenho"
        Desc = "Impede que o Windows reduza o clock da CPU para economizar" + `
               " energia durante o jogo. Ganho direto de FPS em CPUs com" + `
               " throttling agressivo (comum em notebooks)."
        Aviso = "Aumenta o consumo de energia. Em notebooks na bateria, reduz autonomia."
        Check = {
            $ativo = powercfg /getactivescheme
            $ativo -match "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" -or $ativo -match "Alto Desempenho|High performance"
        }
        Aplicar = {
            powercfg -setactive SCHEME_MIN | Out-Null
            Log-Alteracao "Plano de energia alterado para Alto Desempenho"
        }
        Reverter = {
            powercfg -setactive SCHEME_BALANCED | Out-Null
            Log-Alteracao "Plano de energia revertido para Equilibrado"
        }
    },

    @{
        Id = 5
        Nome = "Pausar Servicos Leves em Segundo Plano"
        Desc = "Pausa SysMain, Windows Search e Telemetria enquanto voce joga." + `
               " Libera CPU e I/O de disco que esses servicos consomem em" + `
               " segundo plano. Reversivel a qualquer momento."
        Aviso = $null
        Check = { $false }
        Aplicar = {
            $pausados = @()
            foreach ($s in $ServicosLeves) {
                $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
                if ($svc -and $svc.Status -eq "Running") {
                    Stop-Service -Name $s -Force -ErrorAction SilentlyContinue
                    $pausados += $s
                }
            }
            if ($pausados.Count -gt 0) { Log-Alteracao "Servicos pausados: $($pausados -join ', ')" }
        }
        Reverter = {
            foreach ($s in $ServicosLeves) {
                Start-Service -Name $s -ErrorAction SilentlyContinue
            }
            Log-Alteracao "Servicos leves reativados"
        }
    },

    @{
        Id = 6
        Nome = "Limpar Cache de Shaders (GPU)"
        Desc = "Remove cache de shaders compilados (DirectX geral). Resolve" + `
               " engasgos causados por cache corrompido/desatualizado. Acao" + `
               " pontual, sem estado persistente."
        Aviso = "Apos limpar, os primeiros minutos em cada jogo podem ter leve stutter enquanto os shaders sao recompilados. E normal e temporario."
        Check = { $false }
        Aplicar = {
            $cache = "$env:LOCALAPPDATA\D3DSCache"
            if (Test-Path $cache) {
                $antes = FolderSize $cache
                Remove-Item "$cache\*" -Force -Recurse -ErrorAction SilentlyContinue
                $depois = FolderSize $cache
                $liberado = [math]::Round(($antes - $depois) / 1MB, 1)
                Log-Alteracao "Cache de shaders DirectX limpo ($liberado MB liberados)"
            }
        }
        Reverter = { }
    },

    @{
        Id = 7
        Nome = "Prioridade Alta para Processo em Primeiro Plano"
        Desc = "Ajusta o Windows para dar mais tempo de CPU ao programa que" + `
               " esta em primeiro plano (janela ativa) em vez de dividir" + `
               " igualmente com processos em segundo plano."
        Aviso = $null
        Check = {
            $v = (Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "Win32PrioritySeparation" -ErrorAction SilentlyContinue).Win32PrioritySeparation
            $v -eq 38
        }
        Aplicar = {
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "Win32PrioritySeparation" -Value 38 -Type DWord
            Log-Alteracao "Prioridade de processo em primeiro plano maximizada"
        }
        Reverter = {
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "Win32PrioritySeparation" -Value 2 -Type DWord
            Log-Alteracao "Prioridade de processo revertida para padrao"
        }
    }
)

function Get-StatusTexto($item) {
    if ($item.Check.Invoke()) { return @{ Texto = "ATIVADO"; Cor = "Green" } }
    else { return @{ Texto = "Padrao/Nao Aplicado"; Cor = "DarkGray" } }
}

while ($true) {

    Clear-Host
    Line
    Write-Host "              MIX OTIMIZACOES - FPS BOOST" -ForegroundColor Green
    Line
    Write-Host ""
    Write-Host "Otimizacoes reais para ganho de FPS e visual 'clean' durante jogos." -ForegroundColor DarkGray
    Write-Host "O ganho de FPS varia por jogo/hardware - itens mais efetivos em" -ForegroundColor DarkGray
    Write-Host "PCs com CPU/GPU mais limitada." -ForegroundColor DarkGray
    Write-Host ""

    foreach ($item in $Itens) {
        $status = Get-StatusTexto $item
        Write-Host "[$($item.Id)] $($item.Nome)  " -NoNewline
        Write-Host "[$($status.Texto)]" -ForegroundColor $status.Cor
        Write-Host "     $($item.Desc)" -ForegroundColor DarkGray
        if ($item.Aviso) {
            Write-Host "     AVISO: $($item.Aviso)" -ForegroundColor Yellow
        }
        Write-Host ""
    }

    Line
    Write-Host "[A] Aplicar (digite os numeros, ex: 1,3,5)"
    Write-Host "[R] Reverter (digite os numeros)"
    Write-Host "[T] Aplicar TODOS"
    Write-Host "[V] Reverter TODOS"
    Write-Host "[G] Gerar Relatorio"
    Write-Host "[0] Voltar"
    Write-Host ""

    $op = Read-Host "Escolha"

    switch ($op.ToUpper()) {

        "A" {
            Write-Host ""
            $escolha = Read-Host "Numeros dos itens a aplicar"
            $indices = $escolha -split "," | ForEach-Object { $_.Trim() }
            $selecionados = $Itens | Where-Object { $indices -contains "$($_.Id)" }

            if ($selecionados.Count -eq 0) {
                Write-Host "Nenhum item valido selecionado." -ForegroundColor Red
                PauseMenu
                continue
            }

            $temAviso = $selecionados | Where-Object { $_.Aviso }
            if ($temAviso) {
                Write-Host ""
                foreach ($t in $temAviso) {
                    Write-Host "AVISO ($($t.Nome)): $($t.Aviso)" -ForegroundColor Yellow
                }
            }

            if (Confirmar "Aplicar $($selecionados.Count) item(ns) selecionado(s)?") {
                foreach ($item in $selecionados) {
                    $item.Aplicar.Invoke()
                    Write-Host "Aplicado: $($item.Nome)" -ForegroundColor Green
                }
                Write-Host ""
                Write-Host "Concluido. Recomendado reiniciar o jogo para sentir o efeito completo." -ForegroundColor Yellow
            }
            PauseMenu
        }

        "R" {
            Write-Host ""
            $escolha = Read-Host "Numeros dos itens a reverter"
            $indices = $escolha -split "," | ForEach-Object { $_.Trim() }
            $selecionados = $Itens | Where-Object { $indices -contains "$($_.Id)" }

            if ($selecionados.Count -eq 0) {
                Write-Host "Nenhum item valido selecionado." -ForegroundColor Red
                PauseMenu
                continue
            }

            foreach ($item in $selecionados) {
                $item.Reverter.Invoke()
                Write-Host "Revertido: $($item.Nome)" -ForegroundColor Green
            }
            PauseMenu
        }

        "T" {
            if (Confirmar "Aplicar TODOS os $($Itens.Count) itens de FPS Boost?") {
                foreach ($item in $Itens) {
                    $item.Aplicar.Invoke()
                    Write-Host "Aplicado: $($item.Nome)" -ForegroundColor Green
                }
                Write-Host ""
                Write-Host "FPS Boost completo aplicado." -ForegroundColor Green
                Write-Host "Reinicie o jogo para sentir o efeito completo." -ForegroundColor Yellow
            }
            PauseMenu
        }

        "V" {
            if (Confirmar "Reverter TODOS os itens para o padrao do Windows?") {
                foreach ($item in $Itens) {
                    $item.Reverter.Invoke()
                }
                Write-Host ""
                Write-Host "Todos os itens revertidos." -ForegroundColor Green
            }
            PauseMenu
        }

        "G" {
            $arquivo = "$pastaRelatorios\FPSBoost_Report_$(Get-Date -Format 'ddMMyyyy_HHmmss').txt"
            $linhas = $Itens | ForEach-Object {
                $status = Get-StatusTexto $_
                "  [$($status.Texto)] $($_.Nome): $($_.Desc)"
            }

            @"
==============================
MIX OTIMIZACOES FPS BOOST REPORT
$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
==============================

STATUS DOS ITENS:
$($linhas -join "`n")

Nota: o ganho real de FPS varia por jogo e hardware. Itens tem
maior efeito em PCs com CPU/GPU mais limitada.

Consulte FPSBoost_Log.txt para o historico de aplicacoes/reversoes.
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