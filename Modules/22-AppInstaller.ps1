# ============================================================
# MIX OTIMIZACOES - APP INSTALLER MODULE
# Arquivo: 23-AppInstaller.ps1
# Instala aplicativos direto das URLs oficiais dos fabricantes.
# ============================================================

Clear-Host
$Host.UI.RawUI.WindowTitle = "MIX OTIMIZACOES - APP INSTALLER"
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
    $logFile = "$pastaRelatorios\AppInstaller_Log.txt"
    "$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') - $texto" | Out-File $logFile -Append -Encoding UTF8
}

# ------------------------------------------------------------
# LISTA DE APPS
# Para adicionar um app novo, copie um bloco e ajuste os campos:
#
# Nome         = nome exibido no menu
# Url          = link direto e oficial do instalador
# ArquivoLocal = nome do arquivo temporario baixado
# CaminhoCheck = caminho de arquivo usado para detectar se ja esta instalado
# ArgsInstall  = argumentos de instalacao silenciosa (deixe "" se nao tiver/nao quiser)
# Categoria    = so organizacional, aparece no relatorio
# ------------------------------------------------------------

$Apps = @(

    @{
        Id = 1
        Nome = "Discord"
        Url = "https://discord.com/api/download?platform=win"
        ArquivoLocal = "DiscordSetup.exe"
        CaminhoCheck = "$env:LOCALAPPDATA\Discord\Update.exe"
        ArgsInstall = ""
        Categoria = "Comunicacao"
    },

    @{
        Id = 2
        Nome = "Steam"
        Url = "https://cdn.akamai.steamstatic.com/client/installer/SteamSetup.exe"
        ArquivoLocal = "SteamSetup.exe"
        CaminhoCheck = "$env:ProgramFiles(x86)\Steam\Steam.exe"
        ArgsInstall = "/S"
        Categoria = "Games"
    },

    @{
        Id = 3
        Nome = "Google Chrome"
        Url = "https://dl.google.com/chrome/install/latest/chrome_installer.exe"
        ArquivoLocal = "ChromeSetup.exe"
        CaminhoCheck = "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"
        ArgsInstall = "/silent /install"
        Categoria = "Navegador"
    },

    @{
        Id = 4
        Nome = "7-Zip"
        Url = "https://www.7-zip.org/a/7z2408-x64.exe"
        ArquivoLocal = "7zSetup.exe"
        CaminhoCheck = "$env:ProgramFiles\7-Zip\7zFM.exe"
        ArgsInstall = "/S"
        Categoria = "Utilitarios"
    },

    @{
        Id = 5
        Nome = "VLC Media Player"
        Url = "https://get.videolan.org/vlc/last/win64/vlc-3.0.21-win64.exe"
        ArquivoLocal = "VLCSetup.exe"
        CaminhoCheck = "$env:ProgramFiles\VideoLAN\VLC\vlc.exe"
        ArgsInstall = "/L=1033 /S"
        Categoria = "Midia"
    },

    @{
        Id = 6
        Nome = "Brave Navegador"
        Url = "https://laptop-updates.brave.com/latest/winx64"
        ArquivoLocal = "BraveSetup.exe"
        CaminhoCheck = "${env:ProgramFiles}\BraveSoftware\Brave-Browser\Application\brave.exe"
        ArgsInstall = ""
        Categoria = "Navegador"
    },

    @{
        Id = 7
        Nome = "Epic Games Launcher"
        Url = "https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/download/EpicGamesLauncherInstaller.msi"
        ArquivoLocal = "EpicGamesInstaller.msi"
        CaminhoCheck = "${env:ProgramFiles(x86)}\Epic Games\Launcher\Portal\Binaries\Win64\EpicGamesLauncher.exe"
        ArgsInstall = ""
        Categoria = "Games"
    },

    @{
        Id = 8
        Nome = "Malwarebytes"
        Url = "https://downloads.malwarebytes.com/file/mb-windows"
        ArquivoLocal = "MBSetup.exe"
        CaminhoCheck = "${env:ProgramFiles}\Malwarebytes\Anti-Malware\mbam.exe"
        ArgsInstall = ""
        Categoria = "Seguranca"
    },

    @{
        Id = 9
        Nome = "OBS Studio"
        Url = "VERIFICAR_VERSAO_ATUAL"
        ArquivoLocal = "OBSSetup.exe"
        CaminhoCheck = "${env:ProgramFiles}\obs-studio\bin\64bit\obs64.exe"
        ArgsInstall = ""
        Categoria = "Streaming"
    },

    @{
        Id = 10
        Nome = "Stremio"
        Url = "VERIFICAR_VERSAO_ATUAL"
        ArquivoLocal = "StremioSetup.exe"
        CaminhoCheck = "${env:LOCALAPPDATA}\Programs\LNV Stremio\Stremio.exe"
        ArgsInstall = ""
        Categoria = "Midia"
    },

    @{
        Id = 11
        Nome = "Wise Force Deleter"
        Url = "VERIFICAR_URL_OFICIAL"
        ArquivoLocal = "WiseForceDeleterSetup.exe"
        CaminhoCheck = "${env:ProgramFiles}\Wise\Wise Force Deleter\WiseForceDeleter.exe"
        ArgsInstall = "/verysilent"
        Categoria = "Utilitarios"
    },

    @{
        Id = 12
        Nome = "Revo Uninstaller Free"
        Url = "VERIFICAR_VERSAO_ATUAL"
        ArquivoLocal = "RevoUninstallerSetup.exe"
        CaminhoCheck = "${env:ProgramFiles(x86)}\VS Revo Group\Revo Uninstaller\RevoUn.exe"
        ArgsInstall = ""
        Categoria = "Utilitarios"
    },

    @{
        Id = 13
        Nome = "WinToys"
        Url = "VERIFICAR_GITHUB_RELEASES"
        ArquivoLocal = "WinToysSetup.exe"
        CaminhoCheck = "${env:LOCALAPPDATA}\Microsoft\WindowsApps\WinToys.exe"
        ArgsInstall = ""
        Categoria = "Utilitarios"
    }

    # Adicione novos apps aqui seguindo o mesmo modelo.
)

function Get-AppInstalado($app) {
    return (Test-Path $app.CaminhoCheck)
}

function Instalar-App($app) {
    $destino = "$env:TEMP\$($app.ArquivoLocal)"

    Write-Host ""
    Write-Host "Baixando $($app.Nome)..." -ForegroundColor Cyan
    Write-Host "Fonte: $($app.Url)" -ForegroundColor DarkGray

    try {
        Invoke-WebRequest -Uri $app.Url -OutFile $destino -UseBasicParsing
        Log-Alteracao "$($app.Nome) baixado de $($app.Url)"
    } catch {
        Write-Host ""
        Write-Host "Erro ao baixar $($app.Nome). Verifique sua conexao com a internet." -ForegroundColor Red
        Log-Alteracao "Erro ao baixar $($app.Nome): $($_.Exception.Message)"
        return $false
    }

    Write-Host "Instalando $($app.Nome)..." -ForegroundColor Cyan
    try {
        if ($app.ArgsInstall -and $app.ArgsInstall -ne "") {
            Start-Process -FilePath $destino -ArgumentList $app.ArgsInstall -Wait
        } else {
            Start-Process -FilePath $destino -Wait
        }
        Log-Alteracao "$($app.Nome) instalado"
        return $true
    } catch {
        Write-Host ""
        Write-Host "Erro ao executar o instalador de $($app.Nome)." -ForegroundColor Red
        Log-Alteracao "Erro ao instalar $($app.Nome): $($_.Exception.Message)"
        return $false
    }
}

while ($true) {

    Clear-Host
    Line
    Write-Host "            MIX OTIMIZACOES - APP INSTALLER" -ForegroundColor Green
    Line
    Write-Host ""
    Write-Host "Todos os apps sao baixados direto da URL oficial do fabricante." -ForegroundColor DarkGray
    Write-Host ""

    foreach ($app in $Apps) {
        $instalado = Get-AppInstalado $app
        $status = if ($instalado) { "INSTALADO" } else { "Nao instalado" }
        $cor = if ($instalado) { "Green" } else { "DarkGray" }
        Write-Host "[$($app.Id)] $($app.Nome) " -NoNewline
        Write-Host "[$status]" -ForegroundColor $cor
        Write-Host "     Categoria: $($app.Categoria)" -ForegroundColor DarkGray
    }

    Write-Host ""
    Line
    Write-Host "[I] Instalar (digite os numeros, ex: 1,3)"
    Write-Host "[T] Instalar TODOS os Nao Instalados"
    Write-Host "[V] Ver Detalhes de um App (URL, caminho de instalacao)"
    Write-Host "[G] Gerar Relatorio"
    Write-Host "[0] Voltar"
    Write-Host ""

    $op = Read-Host "Escolha"

    switch ($op.ToUpper()) {

        "I" {
            Write-Host ""
            $escolha = Read-Host "Numeros dos apps a instalar"
            $indices = $escolha -split "," | ForEach-Object { $_.Trim() }
            $selecionados = $Apps | Where-Object { $indices -contains "$($_.Id)" }

            if ($selecionados.Count -eq 0) {
                Write-Host "Nenhum item valido selecionado." -ForegroundColor Red
                PauseMenu
                continue
            }

            Write-Host ""
            Write-Host "Apps selecionados: $($selecionados.Nome -join ', ')" -ForegroundColor Cyan

            if (Confirmar "Baixar e instalar $($selecionados.Count) app(s)?") {
                foreach ($app in $selecionados) {
                    if (Get-AppInstalado $app) {
                        Write-Host ""
                        Write-Host "$($app.Nome) ja esta instalado. Pulando." -ForegroundColor Yellow
                        continue
                    }
                    $ok = Instalar-App $app
                    if ($ok) {
                        Write-Host "$($app.Nome) instalado com sucesso." -ForegroundColor Green
                    }
                }
            }
            PauseMenu
        }

        "T" {
            $naoInstalados = $Apps | Where-Object { -not (Get-AppInstalado $_) }

            if ($naoInstalados.Count -eq 0) {
                Write-Host ""
                Write-Host "Todos os apps da lista ja estao instalados." -ForegroundColor Green
                PauseMenu
                continue
            }

            Write-Host ""
            Write-Host "Serao instalados: $($naoInstalados.Nome -join ', ')" -ForegroundColor Cyan

            if (Confirmar "Instalar todos os $($naoInstalados.Count) apps nao instalados?") {
                foreach ($app in $naoInstalados) {
                    $ok = Instalar-App $app
                    if ($ok) {
                        Write-Host "$($app.Nome) instalado com sucesso." -ForegroundColor Green
                    }
                }
            }
            PauseMenu
        }

        "V" {
            Write-Host ""
            $escolha = Read-Host "Numero do app para ver detalhes"
            $app = $Apps | Where-Object { "$($_.Id)" -eq $escolha.Trim() }

            if ($app) {
                Write-Host ""
                Write-Host "Nome..........: $($app.Nome)"
                Write-Host "Categoria.....: $($app.Categoria)"
                Write-Host "URL Oficial...: $($app.Url)"
                Write-Host "Caminho Check.: $($app.CaminhoCheck)"
                Write-Host "Instalado.....: $(if (Get-AppInstalado $app) {'Sim'} else {'Nao'})"
            } else {
                Write-Host "Numero invalido." -ForegroundColor Red
            }
            PauseMenu
        }

        "G" {
            $arquivo = "$pastaRelatorios\AppInstaller_Report_$(Get-Date -Format 'ddMMyyyy_HHmmss').txt"
            $linhas = $Apps | ForEach-Object {
                $status = if (Get-AppInstalado $_) { "Instalado" } else { "Nao instalado" }
                "  [$status] $($_.Nome) ($($_.Categoria)) - $($_.Url)"
            }

            @"
==============================
MIX OTIMIZACOES APP INSTALLER REPORT
$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
==============================

APPS DISPONIVEIS NESTA FERRAMENTA:
$($linhas -join "`n")

Consulte AppInstaller_Log.txt para o historico de instalacoes.
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