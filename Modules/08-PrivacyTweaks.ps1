# ============================================================
# MIX OTIMIZACOES - PRIVACY TWEAKS MODULE
# Arquivo: 08-PrivacyTweaks.ps1
# ============================================================

Clear-Host
$Host.UI.RawUI.WindowTitle = "MIX OTIMIZACOES - PRIVACY"
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
    $logFile = "$pastaRelatorios\Privacy_Log.txt"
    "$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') - $texto" | Out-File $logFile -Append -Encoding UTF8
}

$Ajustes = @(
    @{ Id = 1; Nome = "Anuncios Personalizados"; Desc = "Desativa ID de publicidade usado para anuncios direcionados"; Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"; Key = "Enabled"; ValorOn = 0; ValorOff = 1 },
    @{ Id = 2; Nome = "Sugestoes do Menu Iniciar"; Desc = "Remove sugestoes de apps e anuncios no Menu Iniciar"; Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Key = "SystemPaneSuggestionsEnabled"; ValorOn = 0; ValorOff = 1 },
    @{ Id = 3; Nome = "Dicas e Truques do Windows"; Desc = "Desativa notificacoes de dicas/sugestoes do sistema"; Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"; Key = "SoftLandingEnabled"; ValorOn = 0; ValorOff = 1 },
    @{ Id = 4; Nome = "Historico de Atividades"; Desc = "Impede o Windows de enviar seu historico de atividades para a Microsoft"; Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager"; Key = "ActivityFeedEnabled"; ValorOn = 0; ValorOff = 1 },
    @{ Id = 5; Nome = "Telemetria (Nivel Basico)"; Desc = "Reduz a telemetria enviada para a Microsoft ao minimo permitido pelo Windows"; Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"; Key = "AllowTelemetry"; ValorOn = 0; ValorOff = 3 },
    @{ Id = 6; Nome = "Localizacao (Rastreamento)"; Desc = "Desativa o servico de localizacao do sistema"; Path = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location"; Key = "Value"; ValorOn = "Deny"; ValorOff = "Allow" },
    @{ Id = 7; Nome = "Cortana"; Desc = "Desativa a Cortana e busca na web pelo Menu Iniciar"; Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"; Key = "CortanaConsent"; ValorOn = 0; ValorOff = 1 }
)

function Aplicar-Ajuste($ajuste, $ativarPrivacidade) {
    $valor = if ($ativarPrivacidade) { $ajuste.ValorOn } else { $ajuste.ValorOff }
    if (-not (Test-Path $ajuste.Path)) { New-Item -Path $ajuste.Path -Force | Out-Null }
    New-ItemProperty -Path $ajuste.Path -Name $ajuste.Key -Value $valor -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
    if ($ajuste.ValorOn -is [string]) {
        New-ItemProperty -Path $ajuste.Path -Name $ajuste.Key -Value $valor -PropertyType String -Force -ErrorAction SilentlyContinue | Out-Null
    }
}

while ($true) {

    Clear-Host
    Line
    Write-Host "              MIX OTIMIZACOES - PRIVACY TWEAKS" -ForegroundColor Green
    Line
    Write-Host ""
    Write-Host "Ajustes disponiveis:" -ForegroundColor Cyan
    Write-Host ""
    foreach ($a in $Ajustes) {
        Write-Host "[$($a.Id)] $($a.Nome)"
        Write-Host "      $($a.Desc)" -ForegroundColor DarkGray
    }
    Write-Host ""
    Line
    Write-Host "[A] Aplicar Ajustes Selecionados (privacidade ativada)"
    Write-Host "[R] Reverter Ajustes Selecionados (padrao do Windows)"
    Write-Host "[T] Aplicar TODOS os Ajustes"
    Write-Host "[V] Reverter TODOS os Ajustes"
    Write-Host "[G] Gerar Relatorio"
    Write-Host "[0] Voltar"
    Write-Host ""

    $op = Read-Host "Escolha"

    switch ($op.ToUpper()) {

        "A" {
            Write-Host ""
            Write-Host "Digite os numeros dos ajustes separados por virgula (ex: 1,2,5)"
            $escolha = Read-Host "Selecao"
            $indices = $escolha -split "," | ForEach-Object { $_.Trim() }
            $selecionados = $Ajustes | Where-Object { $indices -contains "$($_.Id)" }

            if ($selecionados.Count -eq 0) {
                Write-Host "Nenhum item valido selecionado." -ForegroundColor Red
                PauseMenu
                continue
            }

            if (Confirmar "Isso vai aplicar $($selecionados.Count) ajuste(s) de privacidade. Use [R] para reverter depois.") {
                foreach ($a in $selecionados) {
                    Aplicar-Ajuste $a $true
                    Log-Alteracao "Ajuste aplicado: $($a.Nome)"
                    Write-Host "Aplicado: $($a.Nome)" -ForegroundColor Green
                }
                Write-Host ""
                Write-Host "Pode ser necessario reiniciar o Explorer ou o PC para efeito completo." -ForegroundColor Yellow
            }
            PauseMenu
        }

        "R" {
            Write-Host ""
            Write-Host "Digite os numeros dos ajustes separados por virgula (ex: 1,2,5)"
            $escolha = Read-Host "Selecao"
            $indices = $escolha -split "," | ForEach-Object { $_.Trim() }
            $selecionados = $Ajustes | Where-Object { $indices -contains "$($_.Id)" }

            if ($selecionados.Count -eq 0) {
                Write-Host "Nenhum item valido selecionado." -ForegroundColor Red
                PauseMenu
                continue
            }

            foreach ($a in $selecionados) {
                Aplicar-Ajuste $a $false
                Log-Alteracao "Ajuste revertido: $($a.Nome)"
                Write-Host "Revertido: $($a.Nome)" -ForegroundColor Green
            }
            PauseMenu
        }

        "T" {
            if (Confirmar "Isso vai aplicar TODOS os $($Ajustes.Count) ajustes de privacidade.") {
                foreach ($a in $Ajustes) {
                    Aplicar-Ajuste $a $true
                    Log-Alteracao "Ajuste aplicado: $($a.Nome)"
                }
                Write-Host ""
                Write-Host "Todos os ajustes de privacidade foram aplicados." -ForegroundColor Green
                Write-Host "Reinicie o PC para efeito completo." -ForegroundColor Yellow
            }
            PauseMenu
        }

        "V" {
            if (Confirmar "Isso vai reverter TODOS os ajustes para o padrao do Windows.") {
                foreach ($a in $Ajustes) {
                    Aplicar-Ajuste $a $false
                    Log-Alteracao "Ajuste revertido: $($a.Nome)"
                }
                Write-Host ""
                Write-Host "Todos os ajustes foram revertidos." -ForegroundColor Green
            }
            PauseMenu
        }

        "G" {
            $arquivo = "$pastaRelatorios\Privacy_Report_$(Get-Date -Format 'ddMMyyyy_HHmmss').txt"
            $linhas = $Ajustes | ForEach-Object { "  - $($_.Nome): $($_.Desc)" }

            @"
==============================
MIX OTIMIZACOES PRIVACY REPORT
$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
==============================

AJUSTES DISPONIVEIS NESTA FERRAMENTA:
$($linhas -join "`n")

Consulte Privacy_Log.txt para o historico de alteracoes aplicadas/revertidas.
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