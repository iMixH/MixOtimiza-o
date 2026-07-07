# ============================================================
# MIX OTIMIZACOES - SERVICES MANUAL MODE MODULE
# Arquivo: 17-ServicesManual.ps1
# ============================================================

Clear-Host
$Host.UI.RawUI.WindowTitle = "MIX OTIMIZACOES - SERVICES MANUAL MODE"
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
    $logFile = "$pastaRelatorios\ServicesManual_Log.txt"
    "$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') - $texto" | Out-File $logFile -Append -Encoding UTF8
}

function Set-ServicoManual($nome) {
    sc.exe config $nome start= demand | Out-Null
    Stop-Service -Name $nome -Force -ErrorAction SilentlyContinue
}

function Set-ServicoAutomatico($nome) {
    sc.exe config $nome start= auto | Out-Null
    Start-Service -Name $nome -ErrorAction SilentlyContinue
}

function Get-ServicoEmManual($nome) {
    $svc = Get-Service -Name $nome -ErrorAction SilentlyContinue
    if (-not $svc) { return $false }
    return ($svc.StartType -eq "Manual")
}

# ------------------------------------------------------------
# Itens: servicos individuais + acoes de processo
# ------------------------------------------------------------

$Itens = @(

    @{
        Id = 1
        Nome = "Windows Search (WSearch)"
        Desc = "Coloca o indexador de busca do Windows em Manual. Reduz uso de disco/CPU" + `
               " em segundo plano. A busca de arquivos continua funcionando, so fica" + `
               " mais lenta na primeira pesquisa apos o PC ligar."
        Aviso = $null
        Servico = "WSearch"
    },

    @{
        Id = 2
        Nome = "SysMain (Superfetch)"
        Desc = "Coloca o SysMain em Manual. Esse servico pre-carrega apps usados com" + `
               " frequencia na RAM; em SSDs o beneficio e pequeno e ele consome CPU/disco."
        Aviso = $null
        Servico = "SysMain"
    },

    @{
        Id = 3
        Nome = "Telemetria (DiagTrack)"
        Desc = "Coloca o servico de Diagnostico e Telemetria em Manual, reduzindo o" + `
               " envio de dados de uso para a Microsoft em segundo plano."
        Aviso = $null
        Servico = "DiagTrack"
    },

    @{
        Id = 4
        Nome = "Servicos Xbox Live"
        Desc = "Coloca XblAuthManager, XblGameSave e XboxNetApiSvc em Manual." + `
               " Se voce nao joga titulos com integracao Xbox/Game Pass, isso libera" + `
               " recursos sem afetar jogos comuns."
        Aviso = "Se voce usa Xbox Game Pass ou jogos com conquistas via Xbox Live, este item pode atrasar o login desses servicos na primeira vez que abrir o jogo."
        Servico = @("XblAuthManager", "XblGameSave", "XboxNetApiSvc")
    },

    @{
        Id = 5
        Nome = "Fax"
        Desc = "Coloca o servico de Fax em Manual. Praticamente ninguem usa fax hoje em dia."
        Aviso = $null
        Servico = "Fax"
    },

    @{
        Id = 6
        Nome = "Registro Remoto"
        Desc = "Coloca o Registro Remoto em Manual. Reduz superficie de ataque, ja que" + `
               " esse servico permite editar o registro do PC remotamente pela rede."
        Aviso = $null
        Servico = "RemoteRegistry"
    },

    @{
        Id = 7
        Nome = "Spooler de Impressao"
        Desc = "Coloca o servico de impressao em Manual (nao para o servico agora," + `
               " so muda para nao iniciar automatico). Se voce tem impressora, o Windows" + `
               " inicia o servico sozinho quando voce for imprimir."
        Aviso = "Se voce imprime com frequencia, a primeira impressao apos ligar o PC pode demorar alguns segundos a mais."
        Servico = "Spooler"
        ApenasConfig = $true
    },

    @{
        Id = 8
        Nome = "Mapas Offline (MapsBroker)"
        Desc = "Coloca o gerenciador de mapas baixados em Manual. So afeta quem usa" + `
               " o app de Mapas do Windows com mapas offline."
        Aviso = $null
        Servico = "MapsBroker"
    },

    @{
        Id = 9
        Nome = "Biometria (Windows Hello)"
        Desc = "Coloca o servico de biometria em Manual."
        Aviso = "IMPORTANTE: se voce usa login por digital ou reconhecimento facial (Windows Hello), NAO desative este item, ou o login biometrico pode parar de funcionar ate reiniciar o PC."
        Servico = "WbioSrvc"
    },

    @{
        Id = 10
        Nome = "Encerrar OneDrive"
        Desc = "Fecha o OneDrive. Nao desinstala nem para a sincronizacao permanentemente," + `
               " o OneDrive volta a abrir no proximo login do Windows."
        Aviso = $null
        Servico = $null
        Processo = "OneDrive"
    },

    @{
        Id = 11
        Nome = "Encerrar Widgets"
        Desc = "Fecha o processo de Widgets do Windows 11. Reabre sozinho se voce" + `
               " clicar no icone de Widgets na barra de tarefas."
        Aviso = $null
        Servico = $null
        Processo = "Widgets"
    },

    @{
        Id = 12
        Nome = "Encerrar Microsoft Teams"
        Desc = "Fecha o Microsoft Teams a forca."
        Aviso = "Feche qualquer chamada ou conversa importante no Teams antes de usar esta opcao. Nada e salvo automaticamente."
        Servico = $null
        Processo = "Teams"
    },

    @{
        Id = 13
        Nome = "Encerrar Seu Telefone (YourPhone)"
        Desc = "Fecha o app Seu Telefone. Reabre normalmente quando voce abrir de novo."
        Aviso = $null
        Servico = $null
        Processo = "YourPhone"
    }
)

function Get-StatusItem($item) {
    if ($item.Servico) {
        if ($item.Servico -is [array]) {
            $todosManual = $true
            foreach ($s in $item.Servico) {
                if (-not (Get-ServicoEmManual $s)) { $todosManual = $false }
            }
            if ($todosManual) { return @{ Texto = "MANUAL"; Cor = "Green" } }
            else { return @{ Texto = "Automatico (padrao)"; Cor = "DarkGray" } }
        } else {
            if (Get-ServicoEmManual $item.Servico) { return @{ Texto = "MANUAL"; Cor = "Green" } }
            else { return @{ Texto = "Automatico (padrao)"; Cor = "DarkGray" } }
        }
    } else {
        return @{ Texto = "Acao pontual"; Cor = "DarkGray" }
    }
}

function Aplicar-Item($item) {
    if ($item.Servico) {
        $servicos = if ($item.Servico -is [array]) { $item.Servico } else { @($item.Servico) }
        foreach ($s in $servicos) {
            $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
            if ($svc) {
                Set-ServicoManual $s
                Log-Alteracao "Servico '$s' configurado para Manual"
            }
        }
    }
    if ($item.Processo) {
        if (Get-Process -Name $item.Processo -ErrorAction SilentlyContinue) {
            Stop-Process -Name $item.Processo -Force -ErrorAction SilentlyContinue
            Log-Alteracao "Processo encerrado: $($item.Processo)"
        }
    }
}

function Reverter-Item($item) {
    if ($item.Servico) {
        $servicos = if ($item.Servico -is [array]) { $item.Servico } else { @($item.Servico) }
        foreach ($s in $servicos) {
            $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
            if ($svc) {
                Set-ServicoAutomatico $s
                Log-Alteracao "Servico '$s' revertido para Automatico"
            }
        }
    }
    # Itens so de processo (Processo != $null, Servico == $null) nao tem reversao,
    # pois o Windows reabre o app sozinho quando necessario.
}

while ($true) {

    Clear-Host
    Line
    Write-Host "        MIX OTIMIZACOES - SERVICES MANUAL MODE" -ForegroundColor Green
    Line
    Write-Host ""
    Write-Host "Coloca servicos secundarios em Manual (nao desativa/exclui nada)." -ForegroundColor DarkGray
    Write-Host "Servicos criticos do Windows nao aparecem nesta lista." -ForegroundColor DarkGray
    Write-Host ""

    foreach ($item in $Itens) {
        $status = Get-StatusItem $item
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
    Write-Host "[V] Reverter TODOS os Servicos (nao afeta itens de processo)"
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
                    Aplicar-Item $item
                    Write-Host "Aplicado: $($item.Nome)" -ForegroundColor Green
                }
                Write-Host ""
                Write-Host "Concluido. Recomendado reiniciar o PC para efeito completo." -ForegroundColor Yellow
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
                Reverter-Item $item
                Write-Host "Revertido: $($item.Nome)" -ForegroundColor Green
            }
            PauseMenu
        }

        "T" {
            Write-Host ""
            Write-Host "AVISO: isso inclui encerrar OneDrive, Widgets, Teams e Seu Telefone," -ForegroundColor Yellow
            Write-Host "e colocar Windows Hello (biometria) em Manual se estiver ativo." -ForegroundColor Yellow
            if (Confirmar "Aplicar TODOS os $($Itens.Count) itens?") {
                foreach ($item in $Itens) {
                    Aplicar-Item $item
                    Write-Host "Aplicado: $($item.Nome)" -ForegroundColor Green
                }
                Write-Host ""
                Write-Host "Services Manual Mode completo aplicado." -ForegroundColor Green
                Write-Host "Reinicie o PC para efeito completo." -ForegroundColor Yellow
            }
            PauseMenu
        }

        "V" {
            if (Confirmar "Reverter TODOS os servicos para Automatico (padrao do Windows)?") {
                foreach ($item in $Itens) {
                    Reverter-Item $item
                }
                Write-Host ""
                Write-Host "Todos os servicos revertidos para Automatico." -ForegroundColor Green
                Write-Host "Reinicie o PC para aplicar completamente." -ForegroundColor Yellow
            }
            PauseMenu
        }

        "G" {
            $arquivo = "$pastaRelatorios\ServicesManual_Report_$(Get-Date -Format 'ddMMyyyy_HHmmss').txt"
            $linhas = $Itens | ForEach-Object {
                $status = Get-StatusItem $_
                "  [$($status.Texto)] $($_.Nome): $($_.Desc)"
            }

            @"
==============================
MIX OTIMIZACOES SERVICES MANUAL REPORT
$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
==============================

STATUS ATUAL DOS ITENS:
$($linhas -join "`n")

Consulte ServicesManual_Log.txt para o historico de aplicacoes/reversoes.
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