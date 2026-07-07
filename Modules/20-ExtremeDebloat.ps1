# ============================================================
# MIX OTIMIZACOES - EXTREME DEBLOAT MODULE
# Arquivo: 20-ExtremeDebloat.ps1
# Zona Exclusiva: reducao agressiva de processos para
# jogos e desenvolvimento. Reversivel. Nao remove seguranca.
# ============================================================

Clear-Host
$Host.UI.RawUI.WindowTitle = "MIX OTIMIZACOES - EXTREME DEBLOAT"
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
    $logFile = "$pastaRelatorios\ExtremeDebloat_Log.txt"
    "$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') - $texto" | Out-File $logFile -Append -Encoding UTF8
}

function Get-ContagemProcessos {
    return (Get-Process | Measure-Object).Count
}

# ------------------------------------------------------------
# Pacotes UWP considerados bloatware universal (baixo risco)
# ------------------------------------------------------------
$BloatwareSeguro = @(
    "Microsoft.3DBuilder", "Microsoft.MixedReality.Portal", "Microsoft.Microsoft3DViewer",
    "Microsoft.Print3D", "Microsoft.SkypeApp", "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.GetHelp", "Microsoft.Getstarted", "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsSoundRecorder", "Microsoft.Wallet", "Microsoft.MicrosoftOfficeHub",
    "Microsoft.BingNews", "Clipchamp.Clipchamp", "MicrosoftTeams"
)

$pathWidgets = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
$pathWebSearch = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"
$pathBackgroundApps = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
$pathOneDrive = "HKCU:\SOFTWARE\Microsoft\OneDrive"
$pathOneDrivePolicy = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive"
$pathLockScreen = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
$pathMeetNow = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$pathSearchHighlights = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\SearchSettings"

$Itens = @(

    @{
        Id = 1
        Nome = "Remover Apps UWP 'Certamente Bloatware'"
        Desc = "Remove um conjunto de apps pre-instalados que praticamente ninguem usa:" + `
               " 3D Builder, Mixed Reality Portal, Visualizador 3D, Print 3D, Skype" + `
               " (tile promocional), Paciencia, Obter Ajuda, Introducao, Feedback Hub," + `
               " Gravador de Som, Carteira, Office Hub (tile promocional), Noticias," + `
               " Clipchamp e o app Teams (chat pessoal do Win11, nao o Teams de trabalho)."
        Aviso = "Remove apenas para o usuario atual. Para reinstalar, busque o app na Microsoft Store depois."
        Check = { $false }
        Aplicar = {
            $removidos = @()
            foreach ($pkg in $BloatwareSeguro) {
                $app = Get-AppxPackage -Name $pkg -ErrorAction SilentlyContinue
                if ($app) {
                    Remove-AppxPackage -Package $app.PackageFullName -ErrorAction SilentlyContinue
                    $removidos += $pkg
                }
            }
            if ($removidos.Count -gt 0) {
                Log-Alteracao "Apps removidos: $($removidos -join ', ')"
            }
        }
        Reverter = { }
    },

    @{
        Id = 2
        Nome = "Remover Mail e Calendario"
        Desc = "Remove o app nativo de Mail e Calendario do Windows."
        Aviso = "Se voce usa este app para checar e-mails, NAO remova. Use apenas se usa outro cliente (Outlook, navegador, etc)."
        Check = { $false }
        Aplicar = {
            $app = Get-AppxPackage -Name "microsoft.windowscommunicationsapps" -ErrorAction SilentlyContinue
            if ($app) {
                Remove-AppxPackage -Package $app.PackageFullName -ErrorAction SilentlyContinue
                Log-Alteracao "Mail e Calendario removido"
            }
        }
        Reverter = { }
    },

    @{
        Id = 3
        Nome = "Remover OneNote (app da Store)"
        Desc = "Remove a versao do OneNote instalada via Microsoft Store."
        Aviso = "Se voce usa OneNote para anotacoes, NAO remova. Nao afeta o OneNote do Office instalado separadamente."
        Check = { $false }
        Aplicar = {
            $app = Get-AppxPackage -Name "Microsoft.Office.OneNote" -ErrorAction SilentlyContinue
            if ($app) {
                Remove-AppxPackage -Package $app.PackageFullName -ErrorAction SilentlyContinue
                Log-Alteracao "OneNote (Store) removido"
            }
        }
        Reverter = { }
    },

    @{
        Id = 4
        Nome = "Remover People (icone de contatos)"
        Desc = "Remove o app People, usado para fixar contatos na barra de tarefas."
        Aviso = $null
        Check = { $false }
        Aplicar = {
            $app = Get-AppxPackage -Name "Microsoft.People" -ErrorAction SilentlyContinue
            if ($app) {
                Remove-AppxPackage -Package $app.PackageFullName -ErrorAction SilentlyContinue
                Log-Alteracao "People removido"
            }
        }
        Reverter = { }
    },

    @{
        Id = 5
        Nome = "Remover Clima (Weather)"
        Desc = "Remove o app de Clima da Microsoft."
        Aviso = $null
        Check = { $false }
        Aplicar = {
            $app = Get-AppxPackage -Name "Microsoft.BingWeather" -ErrorAction SilentlyContinue
            if ($app) {
                Remove-AppxPackage -Package $app.PackageFullName -ErrorAction SilentlyContinue
                Log-Alteracao "App de Clima removido"
            }
        }
        Reverter = { }
    },

    @{
        Id = 6
        Nome = "Desativar Tarefas Agendadas de Telemetria/Diagnostico"
        Desc = "Desativa tarefas agendadas do Windows relacionadas a coleta de dados" + `
               " de uso, diagnostico de disco e relatorio de erros. Nao afeta tarefas" + `
               " essenciais de manutencao (Windows Update, Defender continuam intactos)."
        Aviso = $null
        Check = {
            $t = Get-ScheduledTask -TaskName "Consolidator" -ErrorAction SilentlyContinue
            $t -and $t.State -eq "Disabled"
        }
        Aplicar = {
            $tarefas = @(
                "Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
                "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
                "Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask",
                "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
                "Microsoft\Windows\Application Experience\ProgramDataUpdater",
                "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
                "Microsoft\Windows\Windows Error Reporting\QueueReporting"
            )
            foreach ($t in $tarefas) {
                Disable-ScheduledTask -TaskPath ("\" + (Split-Path $t) + "\") -TaskName (Split-Path $t -Leaf) -ErrorAction SilentlyContinue | Out-Null
            }
            Log-Alteracao "Tarefas agendadas de telemetria/diagnostico desativadas"
        }
        Reverter = {
            $tarefas = @(
                "Microsoft\Windows\Customer Experience Improvement Program\Consolidator",
                "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip",
                "Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask",
                "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser",
                "Microsoft\Windows\Application Experience\ProgramDataUpdater",
                "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector",
                "Microsoft\Windows\Windows Error Reporting\QueueReporting"
            )
            foreach ($t in $tarefas) {
                Enable-ScheduledTask -TaskPath ("\" + (Split-Path $t) + "\") -TaskName (Split-Path $t -Leaf) -ErrorAction SilentlyContinue | Out-Null
            }
            Log-Alteracao "Tarefas agendadas revertidas para ativado"
        }
    },

    @{
        Id = 7
        Nome = "Desativar Widgets (Windows 11)"
        Desc = "Remove o painel de Widgets e seu icone da barra de tarefas via politica" + `
               " oficial do Windows. Processo em segundo plano do Widgets deixa de rodar."
        Aviso = $null
        Check = {
            $v = (Get-ItemProperty -Path $pathWidgets -Name "AllowNewsAndInterests" -ErrorAction SilentlyContinue).AllowNewsAndInterests
            $v -eq 0
        }
        Aplicar = {
            if (-not (Test-Path $pathWidgets)) { New-Item -Path $pathWidgets -Force | Out-Null }
            Set-ItemProperty -Path $pathWidgets -Name "AllowNewsAndInterests" -Value 0 -Type DWord
            Log-Alteracao "Widgets desativados"
        }
        Reverter = {
            Set-ItemProperty -Path $pathWidgets -Name "AllowNewsAndInterests" -Value 1 -Type DWord
            Log-Alteracao "Widgets revertidos para ativado"
        }
    },

    @{
        Id = 8
        Nome = "Desativar Busca na Web (Bing) no Menu Iniciar"
        Desc = "Faz a busca do Menu Iniciar procurar apenas arquivos e apps locais," + `
               " sem enviar sua digitacao para servidores da Microsoft/Bing."
        Aviso = $null
        Check = {
            $v = (Get-ItemProperty -Path $pathWebSearch -Name "BingSearchEnabled" -ErrorAction SilentlyContinue).BingSearchEnabled
            $v -eq 0
        }
        Aplicar = {
            Set-ItemProperty -Path $pathWebSearch -Name "BingSearchEnabled" -Value 0 -Type DWord
            Set-ItemProperty -Path $pathWebSearch -Name "CortanaConsent" -Value 0 -Type DWord
            Log-Alteracao "Busca na Web (Bing) desativada no Menu Iniciar"
        }
        Reverter = {
            Set-ItemProperty -Path $pathWebSearch -Name "BingSearchEnabled" -Value 1 -Type DWord
            Log-Alteracao "Busca na Web revertida para ativado"
        }
    },

    @{
        Id = 9
        Nome = "Desativar Apps em Segundo Plano (Global)"
        Desc = "Impede que apps UWP instalados continuem rodando em segundo plano" + `
               " quando voce nao esta usando eles ativamente."
        Aviso = "Apps como o Seu Telefone podem parar de notificar em tempo real enquanto nao estiverem abertos."
        Check = {
            $v = (Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -ErrorAction SilentlyContinue).GlobalUserDisabled
            $v -eq 1
        }
        Aplicar = {
            $p = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
            if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
            Set-ItemProperty -Path $p -Name "GlobalUserDisabled" -Value 1 -Type DWord
            Log-Alteracao "Apps em segundo plano desativados globalmente"
        }
        Reverter = {
            $p = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications"
            Set-ItemProperty -Path $p -Name "GlobalUserDisabled" -Value 0 -Type DWord
            Log-Alteracao "Apps em segundo plano revertidos para ativado"
        }
    },

    @{
        Id = 10
        Nome = "Desativar Integracao do OneDrive"
        Desc = "Impede o OneDrive de iniciar automaticamente e sincronizar em segundo" + `
               " plano. NAO desinstala o OneDrive nem apaga seus arquivos na nuvem" + `
               " ou localmente."
        Aviso = "Se voce usa o OneDrive para backup automatico, seus arquivos param de sincronizar ate voce reverter isso."
        Check = {
            $v = (Get-ItemProperty -Path $pathOneDrivePolicy -Name "DisableFileSyncNGSC" -ErrorAction SilentlyContinue).DisableFileSyncNGSC
            $v -eq 1
        }
        Aplicar = {
            if (-not (Test-Path $pathOneDrivePolicy)) { New-Item -Path $pathOneDrivePolicy -Force | Out-Null }
            Set-ItemProperty -Path $pathOneDrivePolicy -Name "DisableFileSyncNGSC" -Value 1 -Type DWord
            Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
            $runKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
            Remove-ItemProperty -Path $runKey -Name "OneDrive" -ErrorAction SilentlyContinue
            Log-Alteracao "OneDrive desativado (sincronizacao e inicializacao automatica)"
        }
        Reverter = {
            Set-ItemProperty -Path $pathOneDrivePolicy -Name "DisableFileSyncNGSC" -Value 0 -Type DWord
            $oneDriveExe = "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe"
            if (Test-Path $oneDriveExe) { Start-Process $oneDriveExe }
            Log-Alteracao "OneDrive revertido para ativado"
        }
    },

    @{
        Id = 11
        Nome = "Desativar Hibernacao"
        Desc = "Remove o arquivo hiberfil.sys e desativa a hibernacao, liberando" + `
               " espaco em disco equivalente a sua RAM instalada (ex: 16GB de RAM" + `
               " = ate 16GB liberados)."
        Aviso = "Voce perde a opcao 'Hibernar' no menu de energia. Suspender (Sleep) continua funcionando normalmente."
        Check = {
            $v = powercfg /a
            -not ($v -match "Hibernar|Hibernate")
        }
        Aplicar = {
            powercfg /hibernate off
            Log-Alteracao "Hibernacao desativada (hiberfil.sys removido)"
        }
        Reverter = {
            powercfg /hibernate on
            Log-Alteracao "Hibernacao revertida para ativado"
        }
    },

    @{
        Id = 12
        Nome = "Desativar Sugestoes e Spotlight na Tela de Bloqueio"
        Desc = "Remove sugestoes de apps, dicas e imagens do Windows Spotlight na" + `
               " tela de bloqueio, deixando so a imagem estatica escolhida por voce."
        Aviso = $null
        Check = {
            $v = (Get-ItemProperty -Path $pathLockScreen -Name "RotatingLockScreenEnabled" -ErrorAction SilentlyContinue).RotatingLockScreenEnabled
            $v -eq 0
        }
        Aplicar = {
            Set-ItemProperty -Path $pathLockScreen -Name "RotatingLockScreenEnabled" -Value 0 -Type DWord
            Set-ItemProperty -Path $pathLockScreen -Name "SubscribedContent-338387Enabled" -Value 0 -Type DWord
            Log-Alteracao "Spotlight e sugestoes da tela de bloqueio desativados"
        }
        Reverter = {
            Set-ItemProperty -Path $pathLockScreen -Name "RotatingLockScreenEnabled" -Value 1 -Type DWord
            Set-ItemProperty -Path $pathLockScreen -Name "SubscribedContent-338387Enabled" -Value 1 -Type DWord
            Log-Alteracao "Spotlight revertido para ativado"
        }
    },

    @{
        Id = 13
        Nome = "Remover Icone 'Meet Now' da Barra de Tarefas"
        Desc = "Remove o icone de videochamada rapida da barra de tarefas (Windows 10)."
        Aviso = $null
        Check = {
            $v = (Get-ItemProperty -Path $pathMeetNow -Name "HideSCAMeetNow" -ErrorAction SilentlyContinue).HideSCAMeetNow
            $v -eq 1
        }
        Aplicar = {
            Set-ItemProperty -Path $pathMeetNow -Name "HideSCAMeetNow" -Value 1 -Type DWord
            Log-Alteracao "Icone Meet Now removido da barra de tarefas"
        }
        Reverter = {
            Set-ItemProperty -Path $pathMeetNow -Name "HideSCAMeetNow" -Value 0 -Type DWord
            Log-Alteracao "Icone Meet Now revertido"
        }
    },

    @{
        Id = 14
        Nome = "Desativar Destaques de Pesquisa (Search Highlights)"
        Desc = "Remove noticias, datas comemorativas e conteudo dinamico da caixa" + `
               " de pesquisa da barra de tarefas."
        Aviso = $null
        Check = {
            $v = (Get-ItemProperty -Path $pathSearchHighlights -Name "IsDynamicSearchBoxEnabled" -ErrorAction SilentlyContinue).IsDynamicSearchBoxEnabled
            $v -eq 0
        }
        Aplicar = {
            if (-not (Test-Path $pathSearchHighlights)) { New-Item -Path $pathSearchHighlights -Force | Out-Null }
            Set-ItemProperty -Path $pathSearchHighlights -Name "IsDynamicSearchBoxEnabled" -Value 0 -Type DWord
            Log-Alteracao "Search Highlights desativado"
        }
        Reverter = {
            Set-ItemProperty -Path $pathSearchHighlights -Name "IsDynamicSearchBoxEnabled" -Value 1 -Type DWord
            Log-Alteracao "Search Highlights revertido"
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
    Write-Host "          MIX OTIMIZACOES - EXTREME DEBLOAT" -ForegroundColor Green
    Write-Host "          (Zona Exclusiva - Jogos e Desenvolvimento)" -ForegroundColor DarkGray
    Line
    Write-Host ""
    Write-Host "Processos rodando agora: " -NoNewline
    Write-Host (Get-ContagemProcessos) -ForegroundColor Yellow
    Write-Host ""
    Write-Host "NAO remove: Windows Defender, Firewall, Windows Update ou qualquer" -ForegroundColor Green
    Write-Host "componente de seguranca. Isso fica sempre intocado." -ForegroundColor Green
    Write-Host ""
    Write-Host "Para reduzir servicos do sistema, use o modulo Services Manual Mode" -ForegroundColor DarkGray
    Write-Host "em conjunto com este. Cada um cobre uma parte diferente." -ForegroundColor DarkGray
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
    Write-Host "[V] Reverter TODOS (o que for reversivel)"
    Write-Host "[P] Ver Contagem de Processos Atual"
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

            $antes = Get-ContagemProcessos
            if (Confirmar "Aplicar $($selecionados.Count) item(ns) selecionado(s)?") {
                foreach ($item in $selecionados) {
                    $item.Aplicar.Invoke()
                    Write-Host "Aplicado: $($item.Nome)" -ForegroundColor Green
                }
                Start-Sleep -Seconds 2
                $depois = Get-ContagemProcessos
                Write-Host ""
                Write-Host "Processos antes: $antes | Processos agora: $depois" -ForegroundColor Cyan
                Write-Host "Recomendado reiniciar o PC para efeito completo em todos os itens." -ForegroundColor Yellow
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
            Write-Host ""
            Write-Host "Apps UWP removidos (itens 1-5) nao sao revertidos automaticamente." -ForegroundColor Yellow
            Write-Host "Reinstale-os pela Microsoft Store se precisar deles de volta." -ForegroundColor Yellow
            PauseMenu
        }

        "T" {
            Write-Host ""
            Write-Host "ATENCAO: Isso vai remover varios apps da Microsoft Store," -ForegroundColor Yellow
            Write-Host "desativar OneDrive, Widgets, hibernacao e mais. Recomendamos" -ForegroundColor Yellow
            Write-Host "criar um Ponto de Restauracao do Windows antes de continuar." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Itens 2, 3, 9 e 10 tem avisos especificos - revise a lista acima" -ForegroundColor Yellow
            Write-Host "antes de confirmar." -ForegroundColor Yellow

            if (Confirmar "Aplicar TODOS os $($Itens.Count) itens do Extreme Debloat?") {
                $antes = Get-ContagemProcessos
                foreach ($item in $Itens) {
                    $item.Aplicar.Invoke()
                    Write-Host "Aplicado: $($item.Nome)" -ForegroundColor Green
                }
                Start-Sleep -Seconds 2
                $depois = Get-ContagemProcessos
                Write-Host ""
                Write-Host "Extreme Debloat completo aplicado." -ForegroundColor Green
                Write-Host "Processos antes: $antes | Processos agora: $depois" -ForegroundColor Cyan
                Write-Host "Reinicie o PC para efeito completo em todos os itens." -ForegroundColor Yellow
            }
            PauseMenu
        }

        "V" {
            if (Confirmar "Reverter todos os itens reversiveis para o padrao do Windows?") {
                foreach ($item in $Itens) {
                    $item.Reverter.Invoke()
                }
                Write-Host ""
                Write-Host "Itens reversiveis revertidos." -ForegroundColor Green
                Write-Host "Apps UWP removidos precisam ser reinstalados pela Microsoft Store." -ForegroundColor Yellow
                Write-Host "Reinicie o PC para aplicar completamente." -ForegroundColor Yellow
            }
            PauseMenu
        }

        "P" {
            Write-Host ""
            Write-Host "Processos rodando agora: $(Get-ContagemProcessos)" -ForegroundColor Cyan
            PauseMenu
        }

        "G" {
            $arquivo = "$pastaRelatorios\ExtremeDebloat_Report_$(Get-Date -Format 'ddMMyyyy_HHmmss').txt"
            $linhas = $Itens | ForEach-Object {
                $status = Get-StatusTexto $_
                "  [$($status.Texto)] $($_.Nome): $($_.Desc)"
            }

            @"
==============================
MIX OTIMIZACOES EXTREME DEBLOAT REPORT
$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
==============================

PROCESSOS RODANDO NO MOMENTO: $(Get-ContagemProcessos)

STATUS DOS ITENS:
$($linhas -join "`n")

Consulte ExtremeDebloat_Log.txt para o historico completo.

Nota: Windows Defender, Firewall e Windows Update nunca sao
alterados por este modulo.
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