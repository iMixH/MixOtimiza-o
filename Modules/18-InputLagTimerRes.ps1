# ============================================================
# MIX OTIMIZACOES - INPUT LAG + TIMER RESOLUTION MODULE
# Arquivo: 18-InputLagTimerRes.ps1
# ============================================================

Clear-Host
$Host.UI.RawUI.WindowTitle = "MIX OTIMIZACOES - INPUT LAG + TIMER RESOLUTION"
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
    $logFile = "$pastaRelatorios\InputLagTimerRes_Log.txt"
    "$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') - $texto" | Out-File $logFile -Append -Encoding UTF8
}

$pathMouse = "HKCU:\Control Panel\Mouse"
$pathGameDVR = "HKCU:\System\GameConfigStore"
$pathMedia = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
$pathGamesTask = "$pathMedia\Tasks\Games"

$Itens = @(

    @{
        Id = 1
        Nome = "Dynamic Tick (Timers do Sistema)"
        Desc = "Desativa o timer dinamico do Windows, reduzindo variacao de timing" + `
               " entre eventos do sistema (jitter). Ajuda o input lag geral."
        Aviso = "Precisa reiniciar o computador para efeito completo."
        Check = { (bcdedit /enum | Select-String "disabledynamictick\s+Yes") -ne $null }
        Aplicar = {
            bcdedit /set disabledynamictick yes | Out-Null
            Log-Alteracao "Dynamic Tick desativado (requer reinicio)"
        }
        Reverter = {
            bcdedit /deletevalue disabledynamictick | Out-Null
            Log-Alteracao "Dynamic Tick revertido para padrao (requer reinicio)"
        }
    },

    @{
        Id = 2
        Nome = "Platform Tick"
        Desc = "Forca o Windows a usar o timer da placa-mae (HPET/APIC) em vez do" + `
               " timer virtualizado, melhorando precisao de timing em jogos."
        Aviso = "Precisa reiniciar o computador para efeito completo. Em alguns PCs mais antigos pode nao trazer ganho perceptivel."
        Check = { (bcdedit /enum | Select-String "useplatformtick\s+Yes") -ne $null }
        Aplicar = {
            bcdedit /set useplatformtick yes | Out-Null
            Log-Alteracao "Platform Tick ativado (requer reinicio)"
        }
        Reverter = {
            bcdedit /deletevalue useplatformtick | Out-Null
            Log-Alteracao "Platform Tick revertido para padrao (requer reinicio)"
        }
    },

    @{
        Id = 3
        Nome = "Sincronizacao de TSC (CPU)"
        Desc = "Ajusta a politica de sincronizacao do contador de ciclos da CPU" + `
               " (TSC) para o modo Enhanced, melhorando consistencia de timing" + `
               " entre nucleos, o que ajuda estabilidade de frametime."
        Aviso = "Precisa reiniciar o computador para efeito completo."
        Check = { (bcdedit /enum | Select-String "tscsyncpolicy\s+Enhanced") -ne $null }
        Aplicar = {
            bcdedit /set tscsyncpolicy Enhanced | Out-Null
            Log-Alteracao "TSC Sync Policy definido como Enhanced (requer reinicio)"
        }
        Reverter = {
            bcdedit /deletevalue tscsyncpolicy | Out-Null
            Log-Alteracao "TSC Sync Policy revertido para padrao (requer reinicio)"
        }
    },

    @{
        Id = 4
        Nome = "USB Selective Suspend"
        Desc = "Impede que o Windows suspenda dispositivos USB para economizar" + `
               " energia. Reduz delay ao 'acordar' mouse/teclado/controle."
        Aviso = $null
        Check = {
            $val = powercfg -query scheme_current sub_usb usbselective 2>$null
            ($val -match "Configuracao Atual de Energia:\s*0x00000000" -or $val -match "Current AC Power Setting Index:\s*0x00000000")
        }
        Aplicar = {
            powercfg -setacvalueindex scheme_current sub_usb usbselective suspend 0 | Out-Null
            powercfg -setactive scheme_current | Out-Null
            Log-Alteracao "USB Selective Suspend desativado"
        }
        Reverter = {
            powercfg -setacvalueindex scheme_current sub_usb usbselective suspend 1 | Out-Null
            powercfg -setactive scheme_current | Out-Null
            Log-Alteracao "USB Selective Suspend revertido para padrao"
        }
    },

    @{
        Id = 5
        Nome = "Aceleracao do Mouse"
        Desc = "Desativa a 'Enhance Pointer Precision'. Cursor responde de forma" + `
               " linear e previsivel ao movimento fisico do mouse."
        Aviso = $null
        Check = {
            $v = (Get-ItemProperty -Path $pathMouse -Name "MouseSpeed" -ErrorAction SilentlyContinue).MouseSpeed
            $v -eq "0"
        }
        Aplicar = {
            Set-ItemProperty -Path $pathMouse -Name "MouseSpeed" -Value "0"
            Set-ItemProperty -Path $pathMouse -Name "MouseThreshold1" -Value "0"
            Set-ItemProperty -Path $pathMouse -Name "MouseThreshold2" -Value "0"
            Log-Alteracao "Aceleracao do mouse desativada"
        }
        Reverter = {
            Set-ItemProperty -Path $pathMouse -Name "MouseSpeed" -Value "1"
            Set-ItemProperty -Path $pathMouse -Name "MouseThreshold1" -Value "6"
            Set-ItemProperty -Path $pathMouse -Name "MouseThreshold2" -Value "10"
            Log-Alteracao "Aceleracao do mouse revertida para padrao"
        }
    },

    @{
        Id = 6
        Nome = "Game DVR / Xbox Game Bar"
        Desc = "Desativa a gravacao em segundo plano do Game DVR, que consome" + `
               " CPU/GPU/disco constantemente durante jogos."
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
        Id = 7
        Nome = "Prioridade Multimidia Maxima (MMCSS)"
        Desc = "Define SystemResponsiveness como 0 (prioridade maxima para audio/jogos" + `
               " sobre tarefas em segundo plano) e ajusta a prioridade da tarefa 'Games'" + `
               " no agendador multimidia do Windows. Mais agressivo que o ajuste padrao" + `
               " (que normalmente usa valor 10-20)."
        Aviso = "Prioridade 0 e o ajuste mais agressivo possivel; em casos raros pode deixar tarefas de audio/rede em segundo plano mais lentas durante o jogo."
        Check = {
            $v = (Get-ItemProperty -Path $pathMedia -Name "SystemResponsiveness" -ErrorAction SilentlyContinue).SystemResponsiveness
            $v -eq 0
        }
        Aplicar = {
            Set-ItemProperty -Path $pathMedia -Name "SystemResponsiveness" -Value 0 -Type DWord
            if (-not (Test-Path $pathGamesTask)) { New-Item -Path $pathGamesTask -Force | Out-Null }
            Set-ItemProperty -Path $pathGamesTask -Name "Priority" -Value 6 -Type DWord
            Log-Alteracao "Prioridade multimidia maxima aplicada (SystemResponsiveness=0, Games Priority=6)"
        }
        Reverter = {
            Set-ItemProperty -Path $pathMedia -Name "SystemResponsiveness" -Value 20 -Type DWord
            Set-ItemProperty -Path $pathGamesTask -Name "Priority" -Value 2 -Type DWord -ErrorAction SilentlyContinue
            Log-Alteracao "Prioridade multimidia revertida para padrao"
        }
    },

    @{
        Id = 8
        Nome = "Plano de Energia Alto Desempenho"
        Desc = "Ativa o plano de energia de Alto Desempenho do Windows, evitando" + `
               " que a CPU reduza clock durante os jogos para economizar energia."
        Aviso = "Aumenta o consumo de energia. Em notebooks na bateria, reduz a autonomia."
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
        Id = 9
        Nome = "Limpar Cache de Rede (DNS)"
        Desc = "Limpa o cache de DNS do Windows. Acao pontual, sem estado persistente."
        Aviso = $null
        Check = { $false }
        Aplicar = {
            ipconfig /flushdns | Out-Null
            Log-Alteracao "Cache de DNS limpo"
        }
        Reverter = { }
    }
)

function Get-StatusTexto($item) {
    if ($item.Check.Invoke()) { return @{ Texto = "ATIVADO"; Cor = "Green" } }
    else { return @{ Texto = "Padrao/Nao Aplicado"; Cor = "DarkGray" } }
}

while ($true) {

    Clear-Host
    Line
    Write-Host "     MIX OTIMIZACOES - INPUT LAG + TIMER RESOLUTION" -ForegroundColor Green
    Line
    Write-Host ""
    Write-Host "Escolha os ajustes individualmente. Cada um explica o que faz." -ForegroundColor DarkGray
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
            $escolha = Read-Host "Numeros dos ajustes a aplicar"
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

            if (Confirmar "Aplicar $($selecionados.Count) ajuste(s) selecionado(s)?") {
                foreach ($item in $selecionados) {
                    $item.Aplicar.Invoke()
                    Write-Host "Aplicado: $($item.Nome)" -ForegroundColor Green
                }
                Write-Host ""
                Write-Host "Concluido. Reinicie o PC se algum item pedir reinicio." -ForegroundColor Yellow
            }
            PauseMenu
        }

        "R" {
            Write-Host ""
            $escolha = Read-Host "Numeros dos ajustes a reverter"
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
            Write-Host ""
            Write-Host "Concluido. Reinicie o PC se algum item pedir reinicio." -ForegroundColor Yellow
            PauseMenu
        }

        "T" {
            Write-Host ""
            Write-Host "AVISO: isso inclui ajustes de boot (Dynamic Tick, Platform Tick, TSC)" -ForegroundColor Yellow
            Write-Host "que requerem reinicio, e prioridade multimidia maxima (item 7)." -ForegroundColor Yellow
            if (Confirmar "Aplicar TODOS os $($Itens.Count) ajustes?") {
                foreach ($item in $Itens) {
                    $item.Aplicar.Invoke()
                    Write-Host "Aplicado: $($item.Nome)" -ForegroundColor Green
                }
                Write-Host ""
                Write-Host "Pack Input Lag + Timer Resolution aplicado por completo." -ForegroundColor Green
                Write-Host "Reinicie o PC para efeito completo (itens de boot precisam de reboot)." -ForegroundColor Yellow
            }
            PauseMenu
        }

        "V" {
            if (Confirmar "Reverter TODOS os ajustes para o padrao do Windows?") {
                foreach ($item in $Itens) {
                    $item.Reverter.Invoke()
                    Write-Host "Revertido: $($item.Nome)" -ForegroundColor Green
                }
                Write-Host ""
                Write-Host "Todos os ajustes revertidos." -ForegroundColor Green
                Write-Host "Reinicie o PC para aplicar completamente." -ForegroundColor Yellow
            }
            PauseMenu
        }

        "G" {
            $arquivo = "$pastaRelatorios\InputLagTimerRes_Report_$(Get-Date -Format 'ddMMyyyy_HHmmss').txt"
            $linhas = $Itens | ForEach-Object {
                $status = Get-StatusTexto $_
                "  [$($status.Texto)] $($_.Nome): $($_.Desc)"
            }

            @"
==============================
MIX OTIMIZACOES INPUT LAG + TIMER RESOLUTION REPORT
$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
==============================

STATUS ATUAL DOS AJUSTES:
$($linhas -join "`n")

Consulte InputLagTimerRes_Log.txt para o historico de aplicacoes/reversoes.
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