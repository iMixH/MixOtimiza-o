# ============================================================
# MIX OTIMIZACOES - FPS ADVISOR MODULE
# Arquivo: 26-FPSAdvisor.ps1
# Recomendacao grafica por jogo/categoria + contador de FPS nativo.
# ============================================================

Clear-Host
$Host.UI.RawUI.WindowTitle = "MIX OTIMIZACOES - FPS ADVISOR"
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

function Log-Alteracao($texto) {
    $logFile = "$pastaRelatorios\FPSAdvisor_Log.txt"
    "$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') - $texto" | Out-File $logFile -Append -Encoding UTF8
}

# ------------------------------------------------------------
# 1. DETECCAO DE CATEGORIA DE GPU
# ------------------------------------------------------------
function Get-CategoriaGPU {
    $gpu = Get-CimInstance Win32_VideoController | Select-Object -First 1
    $nome = $gpu.Name

    $categoria = "NaoIdentificada"

    if ($nome -match "RTX 40[6-9]0" -or $nome -match "RTX 4090") { $categoria = "Ultra" }
    elseif ($nome -match "RTX 30[6-9]0" -or $nome -match "RTX 4060" -or $nome -match "RX 6800" -or $nome -match "RX 6900" -or $nome -match "RX 7700" -or $nome -match "RX 7800" -or $nome -match "RX 7900") { $categoria = "Alta" }
    elseif ($nome -match "RTX 30[5-6]0" -or $nome -match "RTX 2060" -or $nome -match "RX 6600" -or $nome -match "RX 5700") { $categoria = "MediaAlta" }
    elseif ($nome -match "GTX 16[5-6]0" -or $nome -match "RTX 2050" -or $nome -match "RX 570" -or $nome -match "RX 580") { $categoria = "Media" }
    elseif ($nome -match "GTX 10[5-6]0" -or $nome -match "RX 560") { $categoria = "BaixaMedia" }
    elseif ($nome -match "Intel" -or $nome -match "UHD" -or $nome -match "Iris") { $categoria = "Integrada" }
    else { $categoria = "MediaAlta" }  # fallback razoavel se nao reconhecer o modelo

    return @{ Categoria = $categoria; GPU = $nome }
}

# ------------------------------------------------------------
# 2. LISTA DE JOGOS NOMEADOS (curadoria manual, expansivel)
# Estrutura simples: cada jogo aponta pra um "perfil de peso"
# (Leve, Medio, Pesado, MuitoPesado) em vez de texto fixo por
# categoria de GPU - assim a recomendacao e gerada dinamicamente
# e fica facil adicionar jogo novo (so 1 linha).
# ------------------------------------------------------------
$JogosConhecidos = @{
    "Valorant"              = "Leve"
    "CS2"                   = "Leve"
    "CSGO"                   = "Leve"
    "League of Legends"     = "Leve"
    "Dota 2"                = "Medio"
    "Fortnite"              = "Medio"
    "Apex Legends"          = "Medio"
    "Overwatch 2"           = "Medio"
    "Rocket League"         = "Leve"
    "GTA V"                 = "Medio"
    "GTA Online"             = "Medio"
    "Minecraft"             = "Leve"
    "Rainbow Six Siege"      = "Medio"
    "PUBG"                  = "Pesado"
    "Warzone"               = "Pesado"
    "Call of Duty"          = "Pesado"
    "Elden Ring"            = "Pesado"
    "Cyberpunk 2077"        = "MuitoPesado"
    "Red Dead Redemption 2"  = "MuitoPesado"
    "The Witcher 3"          = "Pesado"
    "Baldurs Gate 3"        = "Pesado"
    "Hogwarts Legacy"       = "Pesado"
    "Starfield"             = "MuitoPesado"
    "God of War"            = "Pesado"
    "Forza Horizon 5"       = "Pesado"
    "Assassins Creed Valhalla" = "Pesado"
    "Assassins Creed Mirage" = "Medio"
    "Sons of the Forest"    = "Pesado"
    "Palworld"              = "Medio"
    "Helldivers 2"          = "Pesado"
    "Black Myth Wukong"     = "MuitoPesado"
    "Genshin Impact"        = "Leve"
    "Roblox"                = "Leve"
    "Among Us"              = "Leve"
    "Terraria"              = "Leve"
    "Stardew Valley"        = "Leve"
    "Sea of Thieves"        = "Medio"
    "Destiny 2"             = "Medio"
    "The Finals"            = "Medio"
    "Marvel Rivals"         = "Medio"
    "Escape from Tarkov"    = "Pesado"
}

# ------------------------------------------------------------
# 3. MATRIZ DE RECOMENDACAO: Peso do Jogo x Categoria de GPU
# ------------------------------------------------------------
function Get-Recomendacao($peso, $categoriaGPU) {

    $matriz = @{
        "Leve_Ultra"        = "1440p/4K, tudo no Alto/Epico. GPU tem sobra enorme, priorize nitidez e taxa de atualizacao maxima do monitor."
        "Leve_Alta"         = "1080p/1440p, tudo em Alto. Facilmente 200+ FPS na maioria dos casos."
        "Leve_MediaAlta"    = "1080p, presets em Alto/Medio-Alto, sombras podem ficar ligadas."
        "Leve_Media"        = "1080p, presets em Medio, Anti-Aliasing leve (FXAA) ou desligado."
        "Leve_BaixaMedia"   = "1080p ou 900p, presets em Baixo, sombras desligadas."
        "Leve_Integrada"    = "900p, tudo no minimo, resolucao 3D/render scale em 75-85%."

        "Medio_Ultra"       = "1440p/4K, presets Alto/Ultra, Ray Tracing pode ser testado se o jogo suportar."
        "Medio_Alta"        = "1080p/1440p, presets Alto, RT desligado para maior estabilidade de FPS."
        "Medio_MediaAlta"   = "1080p, presets Medio-Alto, sombras em Medio."
        "Medio_Media"       = "1080p, presets Medio, efeitos de particulas/sombra reduzidos."
        "Medio_BaixaMedia"  = "1080p ou 900p, presets Baixo-Medio, view distance reduzida."
        "Medio_Integrada"   = "900p, tudo no minimo, DLSS/FSR em Performance se disponivel."

        "Pesado_Ultra"      = "1440p/4K, presets Alto/Ultra, RT pode ser ativado com DLSS/FSR Qualidade."
        "Pesado_Alta"       = "1080p/1440p, presets Alto, DLSS/FSR em Qualidade ou Balanceado."
        "Pesado_MediaAlta"  = "1080p, presets Medio, DLSS/FSR em Balanceado/Performance, RT desligado."
        "Pesado_Media"      = "1080p, presets Baixo-Medio, upscaling (DLSS/FSR) em Performance obrigatorio."
        "Pesado_BaixaMedia" = "900p ou 720p, tudo no minimo, upscaling em Performance/Ultra Performance."
        "Pesado_Integrada"  = "720p, tudo no minimo absoluto. Jogo pode ter dificuldade de rodar de forma fluida."

        "MuitoPesado_Ultra"       = "1440p/4K, presets Alto, DLSS/FSR Qualidade recomendado mesmo com GPU forte."
        "MuitoPesado_Alta"        = "1080p/1440p, presets Medio-Alto, DLSS/FSR Balanceado, RT desligado ou minimo."
        "MuitoPesado_MediaAlta"   = "1080p, presets Medio, DLSS/FSR Performance, RT desligado."
        "MuitoPesado_Media"       = "1080p ou 900p, presets Baixo, upscaling em Performance/Ultra Performance."
        "MuitoPesado_BaixaMedia"  = "900p ou 720p, tudo no minimo, considere reduzir resolucao ainda mais."
        "MuitoPesado_Integrada"   = "Jogo provavelmente vai rodar com dificuldade. Considere resolucao bem baixa (720p) e todos os efeitos desligados."
    }

    $chave = "$peso" + "_" + "$categoriaGPU"
    if ($matriz.ContainsKey($chave)) {
        return $matriz[$chave]
    }
    return "Comece nos presets Medios e ajuste conforme o FPS observado (use o contador nativo, opcao 4)."
}

function Get-StatusOverlayFPS {
    $v = (Get-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\GameBar" -Name "ShowFpsCounter" -ErrorAction SilentlyContinue).ShowFpsCounter
    return ($v -eq 1)
}

while ($true) {

    Clear-Host
    Line
    Write-Host "              MIX OTIMIZACOES - FPS ADVISOR" -ForegroundColor Green
    Line
    Write-Host ""

    $gpuInfo = Get-CategoriaGPU
    Write-Host "GPU Detectada......: $($gpuInfo.GPU)"
    Write-Host "Categoria de Perf..: $($gpuInfo.Categoria)"
    Write-Host ""
    Write-Host "IMPORTANTE: nenhuma otimizacao de sistema garante um numero fixo" -ForegroundColor Yellow
    Write-Host "de FPS. O resultado real depende do jogo, da cena e das" -ForegroundColor Yellow
    Write-Host "configuracoes graficas escolhidas DENTRO do jogo." -ForegroundColor Yellow
    Write-Host ""

    Line
    Write-Host "[1] Recomendacao para um Jogo da Lista (nome exato)"
    Write-Host "[2] Recomendacao Generica por Categoria de Jogo (qualquer jogo/launcher)"
    Write-Host "[3] Listar Jogos Disponiveis na Lista"
    Write-Host "[4] Ativar Contador de FPS Nativo (Xbox Game Bar)"
    Write-Host "[5] Como Usar RTSS (RivaTuner) para FPS + Frametime"
    Write-Host "[6] Gerar Relatorio"
    Write-Host "[0] Voltar"
    Write-Host ""

    $op = Read-Host "Escolha"

    switch ($op) {

        "1" {
            Write-Host ""
            $jogo = Read-Host "Digite o nome do jogo (use a opcao 3 para ver os nomes exatos)"

            if (-not $JogosConhecidos.ContainsKey($jogo)) {
                Write-Host ""
                Write-Host "Jogo nao encontrado na lista nomeada." -ForegroundColor Yellow
                Write-Host "Use a opcao [2] para recomendacao generica por categoria de peso," -ForegroundColor Yellow
                Write-Host "que funciona para QUALQUER jogo de qualquer launcher (Steam, Epic," -ForegroundColor Yellow
                Write-Host "GOG, Xbox App, Battle.net, standalone, etc)." -ForegroundColor Yellow
                PauseMenu
                continue
            }

            $peso = $JogosConhecidos[$jogo]
            $rec = Get-Recomendacao $peso $gpuInfo.Categoria

            Write-Host ""
            Line
            Write-Host "RECOMENDACAO PARA $jogo" -ForegroundColor Green
            Write-Host "GPU: $($gpuInfo.GPU) | Categoria: $($gpuInfo.Categoria) | Peso do Jogo: $peso"
            Line
            Write-Host ""
            Write-Host $rec -ForegroundColor Cyan

            Log-Alteracao "Recomendacao consultada: $jogo (peso $peso, GPU categoria $($gpuInfo.Categoria))"
            PauseMenu
        }

        "2" {
            Write-Host ""
            Write-Host "Esta opcao funciona para QUALQUER jogo, de qualquer launcher" -ForegroundColor Cyan
            Write-Host "(Steam, Epic Games, GOG, Xbox App, Battle.net, Riot Client," -ForegroundColor Cyan
            Write-Host "standalone/instalador proprio, etc) - so escolha a categoria" -ForegroundColor Cyan
            Write-Host "de peso mais parecida com o jogo que voce quer otimizar." -ForegroundColor Cyan
            Write-Host ""
            Write-Host "[1] Leve        - Ex: jogos competitivos 2D/3D simples, indies, MOBAs"
            Write-Host "[2] Medio       - Ex: battle royale, mundo aberto medio, RPGs leves"
            Write-Host "[3] Pesado      - Ex: AAA recentes, mundo aberto grande, RPGs pesados"
            Write-Host "[4] Muito Pesado - Ex: AAA com Ray Tracing nativo, graficos de ultima geracao"
            Write-Host ""
            $escolha = Read-Host "Escolha o peso (1-4)"

            $peso = switch ($escolha) {
                "1" { "Leve" }
                "2" { "Medio" }
                "3" { "Pesado" }
                "4" { "MuitoPesado" }
                default { $null }
            }

            if (-not $peso) {
                Write-Host "Opcao invalida." -ForegroundColor Red
                PauseMenu
                continue
            }

            $rec = Get-Recomendacao $peso $gpuInfo.Categoria

            Write-Host ""
            Line
            Write-Host "RECOMENDACAO GENERICA - PESO: $peso" -ForegroundColor Green
            Write-Host "GPU: $($gpuInfo.GPU) | Categoria: $($gpuInfo.Categoria)"
            Line
            Write-Host ""
            Write-Host $rec -ForegroundColor Cyan

            Log-Alteracao "Recomendacao generica consultada: peso $peso, GPU categoria $($gpuInfo.Categoria)"
            PauseMenu
        }

        "3" {
            Write-Host ""
            Write-Host "Jogos disponiveis na lista nomeada:" -ForegroundColor Cyan
            Write-Host ""
            $JogosConhecidos.Keys | Sort-Object | ForEach-Object {
                Write-Host "  - $_ (peso: $($JogosConhecidos[$_]))"
            }
            Write-Host ""
            Write-Host "Total: $($JogosConhecidos.Count) jogos. Para qualquer outro jogo," -ForegroundColor DarkGray
            Write-Host "use a opcao [2] de recomendacao generica por categoria." -ForegroundColor DarkGray
            PauseMenu
        }

        "4" {
            $ativo = Get-StatusOverlayFPS
            Write-Host ""
            Write-Host "Status atual do contador de FPS: " -NoNewline
            if ($ativo) {
                Write-Host "Ativado" -ForegroundColor Green
            } else {
                Write-Host "Desativado" -ForegroundColor DarkGray
            }
            Write-Host ""
            Write-Host "Isso ativa o contador de FPS NATIVO do Windows (Xbox Game Bar)." -ForegroundColor Cyan
            Write-Host "Seguro com qualquer anti-cheat, e recurso oficial do sistema." -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Apos ativar, use WIN + G dentro do jogo e fixe o widget de Desempenho." -ForegroundColor DarkGray
            Write-Host ""

            if (-not $ativo) {
                $r = Read-Host "Ativar agora? (S/N)"
                if ($r -eq "S" -or $r -eq "s") {
                    $pathGB = "HKCU:\SOFTWARE\Microsoft\GameBar"
                    if (-not (Test-Path $pathGB)) { New-Item -Path $pathGB -Force | Out-Null }
                    Set-ItemProperty -Path $pathGB -Name "ShowFpsCounter" -Value 1 -Type DWord
                    Log-Alteracao "Contador de FPS do Xbox Game Bar ativado"
                    Write-Host ""
                    Write-Host "Ativado. Pressione WIN + G dentro do jogo." -ForegroundColor Green
                }
            } else {
                $r = Read-Host "Ja esta ativado. Deseja desativar? (S/N)"
                if ($r -eq "S" -or $r -eq "s") {
                    Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\GameBar" -Name "ShowFpsCounter" -Value 0 -Type DWord
                    Log-Alteracao "Contador de FPS do Xbox Game Bar desativado"
                    Write-Host "Desativado." -ForegroundColor Green
                }
            }
            PauseMenu
        }

        "5" {
            Write-Host ""
            Write-Host "RTSS (RivaTuner Statistics Server) e gratuito, parte do MSI" -ForegroundColor Cyan
            Write-Host "Afterburner. Mostra FPS, grafico de frametime e uso de CPU/GPU." -ForegroundColor Cyan
            Write-Host ""
            Write-Host "Seguro com praticamente todos os anti-cheats (Vanguard, EAC," -ForegroundColor Green
            Write-Host "BattlEye) - roda ha anos no mercado sem interferir no jogo." -ForegroundColor Green
            Write-Host ""
            Write-Host "Como obter:" -ForegroundColor Yellow
            Write-Host "  1. Baixe o MSI Afterburner no site oficial:"
            Write-Host "     www.msi.com/Landing/afterburner/graphics-cards"
            Write-Host "  2. Instale e abra o RivaTuner Statistics Server (incluso)"
            Write-Host "  3. Configure o overlay e abra seu jogo normalmente"
            Write-Host ""
            Write-Host "Este modulo nao baixa nem instala o RTSS automaticamente." -ForegroundColor DarkGray
            PauseMenu
        }

        "6" {
            $arquivo = "$pastaRelatorios\FPSAdvisor_Report_$(Get-Date -Format 'ddMMyyyy_HHmmss').txt"

            @"
==============================
MIX OTIMIZACOES FPS ADVISOR REPORT
$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
==============================

GPU Detectada......: $($gpuInfo.GPU)
Categoria de Perf..: $($gpuInfo.Categoria)

Contador de FPS Nativo (Game Bar): $(if (Get-StatusOverlayFPS) {"Ativado"} else {"Desativado"})

Jogos na lista nomeada: $($JogosConhecidos.Count)
Recomendacao generica por categoria disponivel para qualquer jogo/launcher.

Consulte FPSAdvisor_Log.txt para o historico de consultas.
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