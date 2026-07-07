# ============================================================
# MIX OTIMIZACOES - SPOTIFY INSTALLER MODULE
# Arquivo: 22-SpotifyInstaller.ps1
# ============================================================

Clear-Host
$Host.UI.RawUI.WindowTitle = "MIX OTIMIZACOES - SPOTIFY INSTALLER"
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
    $logFile = "$pastaRelatorios\SpotifyInstaller_Log.txt"
    "$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') - $texto" | Out-File $logFile -Append -Encoding UTF8
}

$UrlSpotify = "https://download.scdn.co/SpotifySetup.exe"
$UrlSpicetify = "https://raw.githubusercontent.com/spicetify/cli/main/install.ps1"

function Get-SpotifyInstalado {
    $caminho = "$env:APPDATA\Spotify\Spotify.exe"
    return (Test-Path $caminho)
}

function Get-SpicetifyInstalado {
    $cmd = Get-Command spicetify -ErrorAction SilentlyContinue
    return ($cmd -ne $null)
}

while ($true) {

    Clear-Host
    Line
    Write-Host "           MIX OTIMIZACOES - SPOTIFY INSTALLER" -ForegroundColor Green
    Line
    Write-Host ""

    $spotifyOk = Get-SpotifyInstalado
    $spicetifyOk = Get-SpicetifyInstalado

    Write-Host "Spotify.....: " -NoNewline
    Write-Host $(if ($spotifyOk) { "Instalado" } else { "Nao instalado" }) -ForegroundColor $(if ($spotifyOk) { "Green" } else { "DarkGray" })
    Write-Host "Spicetify...: " -NoNewline
    Write-Host $(if ($spicetifyOk) { "Instalado" } else { "Nao instalado" }) -ForegroundColor $(if ($spicetifyOk) { "Green" } else { "DarkGray" })
    Write-Host ""

    Line
    Write-Host "[1] Baixar e Instalar Spotify (site oficial)"
    Write-Host "[2] Instalar Spicetify (customizacao de tema/plugins)"
    Write-Host "[3] Atualizar Spicetify (upgrade)"
    Write-Host "[4] Restaurar Spotify ao Padrao (remove customizacoes do Spicetify)"
    Write-Host "[5] Aplicar Configuracao Atual do Spicetify"
    Write-Host "[0] Voltar"
    Write-Host ""

    $op = Read-Host "Escolha"

    switch ($op) {

        "1" {
            Write-Host ""
            Write-Host "Isso vai baixar o instalador oficial do Spotify direto de:" -ForegroundColor Cyan
            Write-Host "$UrlSpotify" -ForegroundColor DarkGray
            Write-Host ""

            if (Confirmar "Deseja baixar e instalar o Spotify agora?") {
                $destino = "$env:TEMP\SpotifySetup.exe"
                Write-Host ""
                Write-Host "Baixando..." -ForegroundColor Cyan
                try {
                    Invoke-WebRequest -Uri $UrlSpotify -OutFile $destino -UseBasicParsing
                    Log-Alteracao "Spotify baixado de $UrlSpotify"

                    Write-Host "Instalando..." -ForegroundColor Cyan
                    Start-Process -FilePath $destino -Wait
                    Log-Alteracao "Instalador do Spotify executado"

                    Write-Host ""
                    Write-Host "Instalacao concluida (ou aberta para conclusao manual)." -ForegroundColor Green
                } catch {
                    Write-Host ""
                    Write-Host "Erro ao baixar/instalar o Spotify. Verifique sua conexao com a internet." -ForegroundColor Red
                    Log-Alteracao "Erro ao baixar/instalar Spotify: $($_.Exception.Message)"
                }
            }
            PauseMenu
        }

        "2" {
            if (-not $spotifyOk) {
                Write-Host ""
                Write-Host "Spotify nao foi detectado neste PC. Instale o Spotify primeiro (opcao 1)." -ForegroundColor Yellow
                PauseMenu
                continue
            }

            Write-Host ""
            Write-Host "O QUE E O SPICETIFY:" -ForegroundColor Cyan
            Write-Host "Ferramenta open-source (nao afiliada ao Spotify) que permite customizar" -ForegroundColor DarkGray
            Write-Host "temas, cores e adicionar extensoes ao cliente do Spotify no desktop." -ForegroundColor DarkGray
            Write-Host ""
            Write-Host "AVISOS IMPORTANTES:" -ForegroundColor Yellow
            Write-Host "- Tecnicamente viola os Termos de Servico do Spotify (o proprio" -ForegroundColor Yellow
            Write-Host "  Spicetify avisa isso na documentacao oficial deles)."
            Write-Host "- Em casos raros, atualizacoes do Spotify podem quebrar a customizacao"
            Write-Host "  ate voce rodar 'spicetify upgrade' novamente."
            Write-Host "- O comando abaixo baixa e executa um script diretamente do"
            Write-Host "  repositorio oficial do Spicetify no GitHub."
            Write-Host ""
            Write-Host "Repositorio oficial: github.com/spicetify/cli" -ForegroundColor DarkGray
            Write-Host ""

            if (Confirmar "Deseja instalar o Spicetify agora?") {
                try {
                    Write-Host ""
                    Write-Host "Baixando e executando instalador oficial do Spicetify..." -ForegroundColor Cyan
                    Invoke-Expression (Invoke-WebRequest -UseBasicParsing -Uri $UrlSpicetify).Content
                    Log-Alteracao "Spicetify instalado via script oficial ($UrlSpicetify)"
                    Write-Host ""
                    Write-Host "Spicetify instalado. Pode ser necessario abrir um novo terminal" -ForegroundColor Green
                    Write-Host "para o comando 'spicetify' ficar disponivel." -ForegroundColor Green
                } catch {
                    Write-Host ""
                    Write-Host "Erro ao instalar o Spicetify." -ForegroundColor Red
                    Log-Alteracao "Erro ao instalar Spicetify: $($_.Exception.Message)"
                }
            }
            PauseMenu
        }

        "3" {
            if (-not $spicetifyOk) {
                Write-Host ""
                Write-Host "Spicetify nao esta instalado. Use a opcao 2 primeiro." -ForegroundColor Yellow
                PauseMenu
                continue
            }
            Write-Host ""
            Write-Host "Atualizando Spicetify..." -ForegroundColor Cyan
            spicetify upgrade
            Log-Alteracao "Spicetify atualizado (upgrade)"
            PauseMenu
        }

        "4" {
            if (-not $spicetifyOk) {
                Write-Host ""
                Write-Host "Spicetify nao esta instalado." -ForegroundColor Yellow
                PauseMenu
                continue
            }

            Write-Host ""
            Write-Host "Isso vai restaurar o Spotify ao estado original, removendo" -ForegroundColor Cyan
            Write-Host "temas e customizacoes aplicadas pelo Spicetify." -ForegroundColor Cyan

            if (Confirmar "Deseja restaurar o Spotify ao padrao agora?") {
                spicetify restore
                spicetify backup
                spicetify apply
                Log-Alteracao "Spotify restaurado ao padrao via spicetify restore/backup/apply"
                Write-Host ""
                Write-Host "Spotify restaurado ao padrao." -ForegroundColor Green
            }
            PauseMenu
        }

        "5" {
            if (-not $spicetifyOk) {
                Write-Host ""
                Write-Host "Spicetify nao esta instalado. Use a opcao 2 primeiro." -ForegroundColor Yellow
                PauseMenu
                continue
            }

            Write-Host ""
            Write-Host "Isso vai fazer backup dos arquivos originais do Spotify e aplicar" -ForegroundColor Cyan
            Write-Host "a configuracao atual do Spicetify (temas/extensoes configurados)." -ForegroundColor Cyan

            if (Confirmar "Aplicar configuracao do Spicetify agora?") {
                Write-Host ""
                spicetify backup
                spicetify apply
                Log-Alteracao "Configuracao do Spicetify aplicada (backup + apply)"
                Write-Host ""
                Write-Host "Configuracao aplicada com sucesso." -ForegroundColor Green
                Write-Host "Se o Spotify estava aberto, feche e abra novamente para ver as mudancas." -ForegroundColor Yellow
            }
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