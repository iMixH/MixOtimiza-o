# ============================================================
# MIX OTIMIZACOES - GPU OPTIMIZER MODULE
# Arquivo: 19-GPUOptimizer.ps1
# Compativel com GPUs NVIDIA e AMD
# ============================================================

Clear-Host
$Host.UI.RawUI.WindowTitle = "MIX OTIMIZACOES - GPU OPTIMIZER"
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
    $logFile = "$pastaRelatorios\GPUOptimizer_Log.txt"
    "$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') - $texto" | Out-File $logFile -Append -Encoding UTF8
}

function FolderSize($Path) {
    if (Test-Path $Path) {
        $size = (Get-ChildItem $Path -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
        if ($size) { return $size }
    }
    return 0
}

$gpu = Get-CimInstance Win32_VideoController | Select-Object -First 1
$fabricante = if ($gpu.Name -match "NVIDIA") { "NVIDIA" }
    elseif ($gpu.Name -match "AMD|Radeon") { "AMD" }
    elseif ($gpu.Name -match "Intel") { "Intel" }
    else { "Desconhecido" }

# ------------------------------------------------------------
# Caminhos de cache conhecidos por fabricante
# ------------------------------------------------------------
$CachesNVIDIA = @(
    "$env:LOCALAPPDATA\NVIDIA\DXCache",
    "$env:LOCALAPPDATA\NVIDIA\GLCache",
    "$env:PROGRAMDATA\NVIDIA Corporation\NV_Cache"
)
$CachesAMD = @(
    "$env:LOCALAPPDATA\AMD\DxCache",
    "$env:LOCALAPPDATA\AMD\DxcCache",
    "$env:LOCALAPPDATA\AMD\GLCache",
    "$env:LOCALAPPDATA\AMD\VkCache"
)
$CacheDirectXGeral = "$env:LOCALAPPDATA\D3DSCache"

function Get-TamanhoCaches($lista) {
    $total = 0
    foreach ($p in $lista) { $total += FolderSize $p }
    return $total
}

while ($true) {

    Clear-Host
    Line
    Write-Host "            MIX OTIMIZACOES - GPU OPTIMIZER" -ForegroundColor Green
    Line
    Write-Host ""
    Write-Host "GPU Detectada....: $($gpu.Name)"
    Write-Host "Fabricante.......: $fabricante"
    Write-Host "Driver...........: $($gpu.DriverVersion)  (Data: $($gpu.DriverDate))"
    Write-Host ""

    $tamNvidia = if ($fabricante -eq "NVIDIA") { [math]::Round((Get-TamanhoCaches $CachesNVIDIA) / 1MB, 1) } else { 0 }
    $tamAMD = if ($fabricante -eq "AMD") { [math]::Round((Get-TamanhoCaches $CachesAMD) / 1MB, 1) } else { 0 }
    $tamDX = [math]::Round((FolderSize $CacheDirectXGeral) / 1MB, 1)

    Line
    Write-Host "[1] Ver Informacoes Detalhadas da GPU"
    if ($fabricante -eq "NVIDIA") {
        Write-Host "[2] Limpar Shader Cache NVIDIA ($tamNvidia MB)"
    } elseif ($fabricante -eq "AMD") {
        Write-Host "[2] Limpar Shader Cache AMD ($tamAMD MB)"
    } else {
        Write-Host "[2] Limpar Shader Cache (fabricante nao identificado automaticamente)"
    }
    Write-Host "[3] Limpar Cache Geral do DirectX ($tamDX MB)"
    Write-Host "[4] Reiniciar Driver de Video (tela pisca por 1-2 segundos, sem fechar jogos)"
    Write-Host "[5] Hardware-Accelerated GPU Scheduling (HAGS)"
    Write-Host "[6] Limpeza Completa de Caches de GPU"
    Write-Host "[7] Gerar Relatorio"
    Write-Host "[0] Voltar"
    Write-Host ""

    $op = Read-Host "Escolha"

    switch ($op) {

        "1" {
            Write-Host ""
            Write-Host "GPU..................: $($gpu.Name)" -ForegroundColor Cyan
            Write-Host "Fabricante............: $fabricante"
            Write-Host "Driver................: $($gpu.DriverVersion)"
            Write-Host "Data do Driver........: $($gpu.DriverDate)"
            Write-Host "Memoria de Video......: $([math]::Round($gpu.AdapterRAM / 1GB, 2)) GB (valor pode ser impreciso em GPUs com mais de 4GB devido a limitacao do WMI)"
            Write-Host "Resolucao Atual.......: $($gpu.CurrentHorizontalResolution) x $($gpu.CurrentVerticalResolution)"
            Write-Host "Taxa de Atualizacao...: $($gpu.CurrentRefreshRate) Hz"
            Write-Host ""
            Write-Host "Dica: para a versao mais recente do driver, consulte o site oficial:" -ForegroundColor Yellow
            if ($fabricante -eq "NVIDIA") { Write-Host "  nvidia.com/drivers" -ForegroundColor Yellow }
            elseif ($fabricante -eq "AMD") { Write-Host "  amd.com/support" -ForegroundColor Yellow }
            Write-Host "Este modulo NAO baixa nem instala drivers automaticamente." -ForegroundColor Yellow
            PauseMenu
        }

        "2" {
            $listaAlvo = if ($fabricante -eq "NVIDIA") { $CachesNVIDIA }
                elseif ($fabricante -eq "AMD") { $CachesAMD }
                else { @() }

            if ($listaAlvo.Count -eq 0) {
                Write-Host ""
                Write-Host "Fabricante de GPU nao reconhecido automaticamente para este item." -ForegroundColor Yellow
                Write-Host "Use a opcao [3] para limpar o cache geral do DirectX." -ForegroundColor Yellow
                PauseMenu
                continue
            }

            Write-Host ""
            Write-Host "O que isso faz: remove arquivos de cache de shaders compilados" -ForegroundColor Cyan
            Write-Host "pela GPU. Esses arquivos sao recriados automaticamente conforme" -ForegroundColor Cyan
            Write-Host "voce joga, mas a limpeza pode resolver bugs visuais, texturas" -ForegroundColor Cyan
            Write-Host "corrompidas ou crashes causados por cache antigo/invalido." -ForegroundColor Cyan
            Write-Host ""
            Write-Host "AVISO: apos limpar, os primeiros minutos em cada jogo podem ter" -ForegroundColor Yellow
            Write-Host "leves engasgos (stutter) enquanto os shaders sao recompilados." -ForegroundColor Yellow
            Write-Host "Isso e normal e temporario." -ForegroundColor Yellow

            if (Confirmar "Deseja limpar o Shader Cache da $fabricante agora?") {
                $antesTotal = Get-TamanhoCaches $listaAlvo
                foreach ($p in $listaAlvo) {
                    if (Test-Path $p) {
                        Remove-Item "$p\*" -Force -Recurse -ErrorAction SilentlyContinue
                    }
                }
                $depoisTotal = Get-TamanhoCaches $listaAlvo
                $liberado = [math]::Round(($antesTotal - $depoisTotal) / 1MB, 1)
                Log-Alteracao "Shader Cache $fabricante limpo ($liberado MB liberados)"
                Write-Host ""
                Write-Host "Shader Cache limpo. $liberado MB liberados." -ForegroundColor Green
            }
            PauseMenu
        }

        "3" {
            Write-Host ""
            Write-Host "O que isso faz: remove o cache de sombreadores compilados pelo" -ForegroundColor Cyan
            Write-Host "DirectX (usado por jogos e apps de todas as GPUs). E recriado" -ForegroundColor Cyan
            Write-Host "automaticamente e pode ajudar com engasgos causados por cache corrompido." -ForegroundColor Cyan

            if (Confirmar "Deseja limpar o cache geral do DirectX?") {
                $antes = FolderSize $CacheDirectXGeral
                if (Test-Path $CacheDirectXGeral) {
                    Remove-Item "$CacheDirectXGeral\*" -Force -Recurse -ErrorAction SilentlyContinue
                }
                $depois = FolderSize $CacheDirectXGeral
                $liberado = [math]::Round(($antes - $depois) / 1MB, 1)
                Log-Alteracao "Cache DirectX limpo ($liberado MB liberados)"
                Write-Host ""
                Write-Host "Cache do DirectX limpo. $liberado MB liberados." -ForegroundColor Green
            }
            PauseMenu
        }

        "4" {
            Write-Host ""
            Write-Host "O que isso faz: reinicia o driver de video sem reiniciar o PC." -ForegroundColor Cyan
            Write-Host "Equivalente ao atalho CTRL+SHIFT+WIN+B do Windows. A tela fica" -ForegroundColor Cyan
            Write-Host "preta/pisca por 1-2 segundos. Jogos e programas abertos NAO fecham." -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Util quando a tela trava, fica com artefatos visuais, ou apos" -ForegroundColor Cyan
            Write-Host "sair do modo tela cheia de um jogo com bug grafico." -ForegroundColor Cyan

            if (Confirmar "Deseja reiniciar o driver de video agora?") {
                Add-Type -AssemblyName System.Windows.Forms
                [System.Windows.Forms.SendKeys]::SendWait("^+%(b)")
                Log-Alteracao "Driver de video reiniciado (atalho Ctrl+Shift+Win+B)"
                Write-Host ""
                Write-Host "Comando enviado. A tela deve piscar em instantes." -ForegroundColor Green
            }
            PauseMenu
        }

        "5" {
            $pathHAGS = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
            $statusAtual = (Get-ItemProperty -Path $pathHAGS -Name "HwSchMode" -ErrorAction SilentlyContinue).HwSchMode

            Write-Host ""
            Write-Host "O que e: Hardware-Accelerated GPU Scheduling permite que a GPU" -ForegroundColor Cyan
            Write-Host "gerencie sua propria fila de trabalho em vez de depender do" -ForegroundColor Cyan
            Write-Host "agendador da CPU. Pode reduzir input lag em alguns jogos e" -ForegroundColor Cyan
            Write-Host "configuracoes, mas o ganho varia bastante por GPU e driver." -ForegroundColor Cyan
            Write-Host ""
            $statusTexto = if ($statusAtual -eq 2) { "ATIVADO" } else { "Desativado (padrao)" }
            $statusCor = if ($statusAtual -eq 2) { "Green" } else { "DarkGray" }
            Write-Host "Status Atual: " -NoNewline
            Write-Host $statusTexto -ForegroundColor $statusCor
            Write-Host ""
            Write-Host "AVISO: requer reiniciar o computador para ter efeito. Em raras" -ForegroundColor Yellow
            Write-Host "combinacoes de driver mais antigo pode causar instabilidade;" -ForegroundColor Yellow
            Write-Host "se notar problemas apos ativar, volte aqui e desative." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "[1] Ativar HAGS"
            Write-Host "[2] Desativar HAGS"
            Write-Host "[0] Cancelar"
            Write-Host ""
            $sub = Read-Host "Escolha"

            if ($sub -eq "1") {
                if (Confirmar "Ativar Hardware-Accelerated GPU Scheduling?") {
                    Set-ItemProperty -Path $pathHAGS -Name "HwSchMode" -Value 2 -Type DWord
                    Log-Alteracao "HAGS ativado (requer reinicio)"
                    Write-Host ""
                    Write-Host "HAGS ativado. Reinicie o PC para aplicar." -ForegroundColor Green
                }
            } elseif ($sub -eq "2") {
                if (Confirmar "Desativar Hardware-Accelerated GPU Scheduling?") {
                    Set-ItemProperty -Path $pathHAGS -Name "HwSchMode" -Value 1 -Type DWord
                    Log-Alteracao "HAGS desativado (requer reinicio)"
                    Write-Host ""
                    Write-Host "HAGS desativado. Reinicie o PC para aplicar." -ForegroundColor Green
                }
            }
            PauseMenu
        }

        "6" {
            Write-Host ""
            Write-Host "Isso vai limpar: Shader Cache da $fabricante + Cache geral do DirectX." -ForegroundColor Cyan
            Write-Host "Os primeiros minutos em cada jogo apos a limpeza podem ter leves" -ForegroundColor Yellow
            Write-Host "engasgos enquanto os shaders sao recompilados. E normal." -ForegroundColor Yellow

            if (Confirmar "Deseja fazer a limpeza completa de caches de GPU agora?") {
                $listaAlvo = if ($fabricante -eq "NVIDIA") { $CachesNVIDIA }
                    elseif ($fabricante -eq "AMD") { $CachesAMD }
                    else { @() }

                $antesTotal = (Get-TamanhoCaches $listaAlvo) + (FolderSize $CacheDirectXGeral)

                foreach ($p in $listaAlvo) {
                    if (Test-Path $p) { Remove-Item "$p\*" -Force -Recurse -ErrorAction SilentlyContinue }
                }
                if (Test-Path $CacheDirectXGeral) {
                    Remove-Item "$CacheDirectXGeral\*" -Force -Recurse -ErrorAction SilentlyContinue
                }

                $depoisTotal = (Get-TamanhoCaches $listaAlvo) + (FolderSize $CacheDirectXGeral)
                $liberado = [math]::Round(($antesTotal - $depoisTotal) / 1MB, 1)

                Log-Alteracao "Limpeza completa de caches de GPU executada ($liberado MB liberados)"
                Write-Host ""
                Write-Host "Limpeza completa concluida. $liberado MB liberados." -ForegroundColor Green
            }
            PauseMenu
        }

        "7" {
            $arquivo = "$pastaRelatorios\GPUOptimizer_Report_$(Get-Date -Format 'ddMMyyyy_HHmmss').txt"
            $pathHAGS = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
            $statusHAGS = (Get-ItemProperty -Path $pathHAGS -Name "HwSchMode" -ErrorAction SilentlyContinue).HwSchMode
            $statusHAGSTexto = if ($statusHAGS -eq 2) { "Ativado" } else { "Desativado" }

            @"
==============================
MIX OTIMIZACOES GPU OPTIMIZER REPORT
$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
==============================

GPU..................: $($gpu.Name)
Fabricante...........: $fabricante
Driver...............: $($gpu.DriverVersion) ($($gpu.DriverDate))
HAGS.................: $statusHAGSTexto

Cache Shader ($fabricante)...: $(if($fabricante -eq "NVIDIA"){$tamNvidia}elseif($fabricante -eq "AMD"){$tamAMD}else{"N/D"}) MB
Cache DirectX Geral..........: $tamDX MB

Consulte GPUOptimizer_Log.txt para o historico de limpezas e alteracoes.
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