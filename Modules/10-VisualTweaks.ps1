# ============================================================
# MIX OTIMIZACOES - VISUAL TWEAKS MODULE
# Arquivo: 10-VisualTweaks.ps1
# ============================================================

Clear-Host
$Host.UI.RawUI.WindowTitle = "MIX OTIMIZACOES - VISUAL TWEAKS"
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
    $logFile = "$pastaRelatorios\VisualTweaks_Log.txt"
    "$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') - $texto" | Out-File $logFile -Append -Encoding UTF8
}

$PathVisualFX = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
$PathAdvanced = "HKCU:\Control Panel\Desktop"
$PathAnimations = "HKCU:\Control Panel\Desktop\WindowMetrics"
$PathDWM = "HKCU:\Software\Microsoft\Windows\DWM"

while ($true) {

    Clear-Host
    Line
    Write-Host "            MIX OTIMIZACOES - VISUAL TWEAKS" -ForegroundColor Green
    Line
    Write-Host ""
    Write-Host "Ajustes visuais alteram a aparencia do Windows para ganhar" -ForegroundColor DarkGray
    Write-Host "performance em PCs mais fracos ou GPUs integradas." -ForegroundColor DarkGray
    Write-Host ""

    Line
    Write-Host "[1] Modo Performance (desativa quase tudo - PCs fracos)"
    Write-Host "[2] Modo Balanceado (mantem visual basico, remove excessos)"
    Write-Host "[3] Restaurar Aparencia Padrao do Windows"
    Write-Host "[4] Desativar Transparencia"
    Write-Host "[5] Desativar Animacoes de Janela"
    Write-Host "[6] Desativar Efeito de Sombra em Janelas"
    Write-Host "[7] Ver Configuracao Atual"
    Write-Host "[8] Gerar Relatorio"
    Write-Host "[0] Voltar"
    Write-Host ""

    $op = Read-Host "Escolha"

    switch ($op) {

        "1" {
            if (Confirmar "Isso vai desativar quase todos os efeitos visuais para maxima performance.") {
                if (-not (Test-Path $PathVisualFX)) { New-Item -Path $PathVisualFX -Force | Out-Null }
                New-ItemProperty -Path $PathVisualFX -Name "VisualFXSetting" -Value 2 -PropertyType DWord -Force | Out-Null
                Set-ItemProperty -Path $PathAdvanced -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -ErrorAction SilentlyContinue
                Set-ItemProperty -Path $PathDWM -Name "EnableAeroPeek" -Value 0 -ErrorAction SilentlyContinue
                Log-Alteracao "Modo Performance aplicado (efeitos visuais minimos)"
                Write-Host ""
                Write-Host "Modo Performance aplicado." -ForegroundColor Green
                Write-Host "Relogue ou reinicie o Explorer para ver o efeito completo." -ForegroundColor Yellow
            }
            PauseMenu
        }

        "2" {
            if (Confirmar "Isso vai deixar o Windows com aparencia customizada equilibrada.") {
                if (-not (Test-Path $PathVisualFX)) { New-Item -Path $PathVisualFX -Force | Out-Null }
                New-ItemProperty -Path $PathVisualFX -Name "VisualFXSetting" -Value 3 -PropertyType DWord -Force | Out-Null
                Log-Alteracao "Modo Balanceado aplicado"
                Write-Host ""
                Write-Host "Modo Balanceado aplicado." -ForegroundColor Green
            }
            PauseMenu
        }

        "3" {
            if (Confirmar "Isso vai restaurar a aparencia padrao do Windows (deixar o Windows escolher).") {
                if (-not (Test-Path $PathVisualFX)) { New-Item -Path $PathVisualFX -Force | Out-Null }
                New-ItemProperty -Path $PathVisualFX -Name "VisualFXSetting" -Value 0 -PropertyType DWord -Force | Out-Null
                Set-ItemProperty -Path $PathDWM -Name "EnableAeroPeek" -Value 1 -ErrorAction SilentlyContinue
                Log-Alteracao "Aparencia padrao do Windows restaurada"
                Write-Host ""
                Write-Host "Aparencia padrao restaurada." -ForegroundColor Green
                Write-Host "Relogue ou reinicie o Explorer para ver o efeito completo." -ForegroundColor Yellow
            }
            PauseMenu
        }

        "4" {
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0 -ErrorAction SilentlyContinue
            Log-Alteracao "Transparencia desativada"
            Write-Host ""
            Write-Host "Transparencia desativada." -ForegroundColor Green
            PauseMenu
        }

        "5" {
            Set-ItemProperty -Path $PathAdvanced -Name "MinAnimate" -Value 0 -ErrorAction SilentlyContinue
            Log-Alteracao "Animacoes de janela desativadas"
            Write-Host ""
            Write-Host "Animacoes de janela desativadas." -ForegroundColor Green
            PauseMenu
        }

        "6" {
            Set-ItemProperty -Path $PathDWM -Name "DisallowShaking" -Value 1 -ErrorAction SilentlyContinue
            New-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x9E,0x1E,0x07,0x80,0x12,0x00,0x00,0x00)) -PropertyType Binary -Force -ErrorAction SilentlyContinue | Out-Null
            Log-Alteracao "Sombras de janela reduzidas"
            Write-Host ""
            Write-Host "Sombras reduzidas." -ForegroundColor Green
            PauseMenu
        }

        "7" {
            Write-Host ""
            $atual = (Get-ItemProperty -Path $PathVisualFX -Name "VisualFXSetting" -ErrorAction SilentlyContinue).VisualFXSetting
            $descricao = switch ($atual) {
                0 { "Deixar o Windows escolher (padrao)" }
                1 { "Ajustar para melhor aparencia" }
                2 { "Ajustar para melhor desempenho" }
                3 { "Personalizado" }
                default { "Nao definido (padrao do sistema)" }
            }
            Write-Host "Configuracao atual de efeitos visuais: $descricao"
            PauseMenu
        }

        "8" {
            $arquivo = "$pastaRelatorios\VisualTweaks_Report_$(Get-Date -Format 'ddMMyyyy_HHmmss').txt"
            $atual = (Get-ItemProperty -Path $PathVisualFX -Name "VisualFXSetting" -ErrorAction SilentlyContinue).VisualFXSetting

            @"
==============================
MIX OTIMIZACOES VISUAL TWEAKS REPORT
$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
==============================

Configuracao Atual (VisualFXSetting): $atual

Consulte VisualTweaks_Log.txt para o historico de alteracoes aplicadas.
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