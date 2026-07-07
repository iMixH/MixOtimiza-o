# ============================================================
# MIX OTIMIZACOES - LOW LATENCY MODE MODULE
# Arquivo: 16-LowLatency.ps1
# ============================================================

Clear-Host
$Host.UI.RawUI.WindowTitle = "MIX OTIMIZACOES - LOW LATENCY MODE"
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
    $logFile = "$pastaRelatorios\LowLatency_Log.txt"
    "$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') - $texto" | Out-File $logFile -Append -Encoding UTF8
}

# ------------------------------------------------------------
# Cada item tem: Id, Nome, Descricao (o que faz e o que remove/muda),
# Aviso (se precisar), funcoes de Aplicar/Reverter e de checar status
# ------------------------------------------------------------

$pathMedia  = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
$pathVisual = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
$pathMouse  = "HKCU:\Control Panel\Mouse"
$pathGameDVR = "HKCU:\System\GameConfigStore"

$Itens = @(

    @{
        Id = 1
        Nome = "Dynamic Tick (Timers do Sistema)"
        Desc = "Desativa o timer dinamico do Windows. Reduz variacao de timing entre" + `
               " frames (jitter), ajudando o input lag. Requer reiniciar o PC para efeito completo."
        Aviso = "Precisa reiniciar o computador apos aplicar ou reverter."
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
        Nome = "USB Selective Suspend"
        Desc = "Impede que o Windows suspenda dispositivos USB (mouse, teclado, headset)" + `
               " para economizar energia. Evita microtravamentos/delay ao 'acordar' o periferico."
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
        Id = 3
        Nome = "Aceleracao do Mouse"
        Desc = "Desativa a 'Enhance Pointer Precision' do Windows. Faz o cursor responder" + `
               " de forma linear e previsivel ao movimento fisico do mouse (padrao usado" + `
               " em jogos competitivos)."
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
        Id = 4
        Nome = "Prioridade Multimidia (MMCSS)"
        Desc = "Ajusta o agendador de tarefas multimidia do Windows para dar mais" + `
               " prioridade a processos de jogos/audio e reduz o throttling de rede" + `
               " para tarefas em segundo plano."
        Aviso = $null
        Check = {
            $v = (Get-ItemProperty -Path $pathMedia -Name "SystemResponsiveness" -ErrorAction SilentlyContinue).SystemResponsiveness
            $v -eq 10
        }
        Aplicar = {
            Set-ItemProperty -Path $pathMedia -Name "SystemResponsiveness" -Value 10 -Type DWord
            Set-ItemProperty -Path $pathMedia -Name "NetworkThrottlingIndex" -Value 0xFFFFFFFF -Type DWord
            Log-Alteracao "Prioridade multimidia ajustada (SystemResponsiveness=10)"
        }
        Reverter = {
            Set-ItemProperty -Path $pathMedia -Name "SystemResponsiveness" -Value 20 -Type DWord
            Remove-ItemProperty -Path $pathMedia -Name "NetworkThrottlingIndex" -ErrorAction SilentlyContinue
            Log-Alteracao "Prioridade multimidia revertida para padrao"
        }
    },

    @{
        Id = 5
        Nome = "TCP Autotuning"
        Desc = "Desativa o ajuste automatico de janela TCP do Windows. Pode reduzir" + `
               " variacao de latencia de rede em algumas configuracoes, mas em conexoes" + `
               " modernas o ganho costuma ser pequeno."
        Aviso = $null
        Check = {
            $v = netsh int tcp show global | Select-String "Nivel de Ajuste Automatico do Fator de Escalonamento do Receptor|Receive Window Auto-Tuning Level"
            $v -match "disabled|desativado"
        }
        Aplicar = {
            netsh int tcp set global autotuninglevel=disabled | Out-Null
            Log-Alteracao "TCP Autotuning desativado"
        }
        Reverter = {
            netsh int tcp set global autotuninglevel=normal | Out-Null
            Log-Alteracao "TCP Autotuning revertido para normal"
        }
    },

    @{
        Id = 6
        Nome = "Game DVR / Xbox Game Bar"
        Desc = "Desativa a gravacao em segundo plano do Game DVR (Xbox Game Bar)." + `
               " Esse recurso consome CPU/GPU e disco constantemente enquanto voce joga."
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
        Nome = "Efeitos Visuais do Windows"
        Desc = "Reduz animacoes, sombras e transparencias da interface para liberar" + `
               " recursos de CPU/GPU, especialmente util em PCs mais fracos."
        Aviso = $null
        Check = {
            $v = (Get-ItemProperty -Path $pathVisual -Name "VisualFXSetting" -ErrorAction SilentlyContinue).VisualFXSetting
            $v -eq 2
        }
        Aplicar = {
            if (-not (Test-Path $pathVisual)) { New-Item -Path $pathVisual -Force | Out-Null }
            Set-ItemProperty -Path $pathVisual -Name "VisualFXSetting" -Value 2 -Type DWord
            Log-Alteracao "Efeitos visuais reduzidos"
        }
        Reverter = {
            Set-ItemProperty -Path $pathVisual -Name "VisualFXSetting" -Value 0 -Type DWord
            Log-Alteracao "Efeitos visuais revertidos para padrao"
        }
    },

    @{
        Id = 8
        Nome = "Encerrar Processos Secundarios (Widgets, RuntimeBroker, YourPhone)"
        Desc = "Fecha processos leves em segundo plano que o Windows recria sozinho" + `
               " quando necessario. Nao remove nem desinstala nada, apenas libera" + `
               " RAM/CPU momentaneamente."
        Aviso = $null
        Check = { $false }  # acao pontual, nao tem estado persistente pra reverter
        Aplicar = {
            $encerrados = @()
            foreach ($proc in @("Widgets", "RuntimeBroker", "backgroundTaskHost", "YourPhone")) {
                if (Get-Process -Name $proc -ErrorAction SilentlyContinue) {
                    Stop-Process -Name $proc -Force -ErrorAction SilentlyContinue
                    $encerrados += $proc
                }
            }
            if ($encerrados.Count -gt 0) {
                Log-Alteracao "Processos encerrados: $($encerrados -join ', ')"
            }
        }
        Reverter = { }  # nao aplicavel
    },

    @{
        Id = 9
        Nome = "Encerrar Microsoft Teams"
        Desc = "Fecha o Microsoft Teams a forca. ATENCAO: nao salva nada em aberto" + `
               " e derruba chamadas em andamento. Item separado dos demais de proposito."
        Aviso = "Feche qualquer chamada ou conversa importante no Teams antes de usar esta opcao."
        Check = { $false }
        Aplicar = {
            if (Get-Process -Name "Teams" -ErrorAction SilentlyContinue) {
                Stop-Process -Name "Teams" -Force -ErrorAction SilentlyContinue
                Log-Alteracao "Microsoft Teams encerrado"
            }
        }
        Reverter = { }
    },

    @{
        Id = 10
        Nome = "Limpar Arquivos Temporarios"
        Desc = "Remove arquivos da pasta TEMP do usuario atual. Libera espaco em disco."
        Aviso = $null
        Check = { $false }
        Aplicar = {
            Remove-Item "$env:TEMP\*" -Force -Recurse -ErrorAction SilentlyContinue
            Log-Alteracao "Arquivos temporarios limpos"
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
    Write-Host "         MIX OTIMIZACOES - LOW LATENCY MODE" -ForegroundColor Green
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
                    Write-Host "AVISO: $($t.Aviso)" -ForegroundColor Yellow
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
            Write-Host "AVISO: isso inclui encerrar o Microsoft Teams a forca (item 9)." -ForegroundColor Yellow
            if (Confirmar "Aplicar TODOS os $($Itens.Count) ajustes?") {
                foreach ($item in $Itens) {
                    $item.Aplicar.Invoke()
                    Write-Host "Aplicado: $($item.Nome)" -ForegroundColor Green
                }
                Write-Host ""
                Write-Host "Low Latency Mode completo aplicado." -ForegroundColor Green
                Write-Host "Reinicie o PC para efeito completo (Dynamic Tick precisa de reboot)." -ForegroundColor Yellow
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
            $arquivo = "$pastaRelatorios\LowLatency_Report_$(Get-Date -Format 'ddMMyyyy_HHmmss').txt"
            $linhas = $Itens | ForEach-Object {
                $status = Get-StatusTexto $_
                "  [$($status.Texto)] $($_.Nome): $($_.Desc)"
            }

            @"
==============================
MIX OTIMIZACOES LOW LATENCY REPORT
$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
==============================

STATUS ATUAL DOS AJUSTES:
$($linhas -join "`n")

Consulte LowLatency_Log.txt para o historico de aplicacoes/reversoes.
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