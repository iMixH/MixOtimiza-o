# ============================================================
# MIX OTIMIZACOES - THREAT SCANNER MODULE
# Arquivo: 26-ThreatScanner.ps1
# Scanner de indicadores heuristicos (IOC). NAO substitui um
# antivirus completo - complementa o Windows Defender.
# ============================================================

Clear-Host
$Host.UI.RawUI.WindowTitle = "MIX OTIMIZACOES - THREAT SCANNER"
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

function Log-Achado($texto) {
    $logFile = "$pastaRelatorios\ThreatScanner_Log.txt"
    "$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') - $texto" | Out-File $logFile -Append -Encoding UTF8
}

$achados = @()

function Add-Achado($categoria, $item, $motivo, $severidade) {
    $script:achados += [PSCustomObject]@{
        Categoria  = $categoria
        Item       = $item
        Motivo     = $motivo
        Severidade = $severidade
    }
}

function Cor-Severidade($sev) {
    switch ($sev) {
        "Alta"  { return "Red" }
        "Media" { return "Yellow" }
        default { return "DarkGray" }
    }
}

# ------------------------------------------------------------
# 1. Status do Windows Defender
# ------------------------------------------------------------
function Verificar-Defender {
    Write-Host "Verificando status do Windows Defender..." -ForegroundColor Cyan
    try {
        $status = Get-MpComputerStatus
        if (-not $status.AntivirusEnabled) {
            Add-Achado "Antivirus" "Windows Defender" "Protecao em tempo real esta DESATIVADA" "Alta"
        }
        if (-not $status.RealTimeProtectionEnabled) {
            Add-Achado "Antivirus" "Windows Defender" "Protecao em tempo real desativada" "Alta"
        }
        $diasDesdeAtualizacao = (New-TimeSpan -Start $status.AntivirusSignatureLastUpdated -End (Get-Date)).Days
        if ($diasDesdeAtualizacao -gt 7) {
            Add-Achado "Antivirus" "Definicoes de Virus" "Nao atualizadas ha $diasDesdeAtualizacao dias" "Media"
        }

        # Exclusoes do Defender configuradas (podem ser usadas por malware para se esconder)
        $exclusoesPath = (Get-MpPreference).ExclusionPath
        if ($exclusoesPath -and $exclusoesPath.Count -gt 0) {
            foreach ($exc in $exclusoesPath) {
                Add-Achado "Antivirus" "Exclusao do Defender" "Pasta excluida da varredura: $exc" "Media"
            }
        }
    } catch {
        Add-Achado "Antivirus" "Windows Defender" "Nao foi possivel consultar o status (pode ser outro antivirus instalado)" "Baixa"
    }
}

# ------------------------------------------------------------
# 2. Locais de persistencia (Run keys, Startup)
# ------------------------------------------------------------
function Verificar-Persistencia {
    Write-Host "Verificando locais de inicializacao automatica..." -ForegroundColor Cyan
    $chaves = @(
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce"
    )

    foreach ($chave in $chaves) {
        if (Test-Path $chave) {
            $props = Get-ItemProperty -Path $chave -ErrorAction SilentlyContinue
            foreach ($prop in $props.PSObject.Properties) {
                if ($prop.Name -in @("PSPath", "PSParentPath", "PSChildName", "PSDrive", "PSProvider")) { continue }
                $valor = $prop.Value

                # Sinais suspeitos: roda de Temp, AppData com nome aleatorio, ou usa PowerShell/mshta/regsvr32 encadeado com URL
                if ($valor -match "\\Temp\\|\\AppData\\Local\\Temp") {
                    Add-Achado "Inicializacao" $prop.Name "Programa inicia a partir da pasta TEMP: $valor" "Alta"
                }
                if ($valor -match "powershell.*-enc|powershell.*-e |mshta.*http|regsvr32.*http") {
                    Add-Achado "Inicializacao" $prop.Name "Comando codificado/remoto suspeito: $valor" "Alta"
                }
            }
        }
    }
}

# ------------------------------------------------------------
# 3. Arquivo Hosts adulterado
# ------------------------------------------------------------
function Verificar-Hosts {
    Write-Host "Verificando arquivo hosts..." -ForegroundColor Cyan
    $hostsPath = "$env:windir\System32\drivers\etc\hosts"
    if (Test-Path $hostsPath) {
        $linhas = Get-Content $hostsPath | Where-Object { $_ -notmatch "^\s*#" -and $_.Trim() -ne "" }
        foreach ($linha in $linhas) {
            if ($linha -match "\S") {
                Add-Achado "Rede" "Arquivo Hosts" "Entrada customizada encontrada: $linha" "Media"
            }
        }
    }
}

# ------------------------------------------------------------
# 4. Extensoes duplas (disfarce classico)
# ------------------------------------------------------------
function Verificar-ExtensoesDuplas {
    Write-Host "Verificando arquivos com extensao dupla (disfarce)..." -ForegroundColor Cyan
    $pastasAlvo = @("$env:USERPROFILE\Downloads", "$env:USERPROFILE\Desktop", "$env:TEMP")
    $padraoSuspeito = '\.(pdf|docx?|xlsx?|jpg|jpeg|png|txt|zip|rar)\.(exe|scr|bat|cmd|vbs|js|ps1)$'

    foreach ($pasta in $pastasAlvo) {
        if (Test-Path $pasta) {
            $arquivos = Get-ChildItem -Path $pasta -File -Recurse -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -match $padraoSuspeito }
            foreach ($a in $arquivos) {
                Add-Achado "Arquivos" $a.FullName "Extensao dupla suspeita (disfarce de tipo de arquivo)" "Alta"
            }
        }
    }
}

# ------------------------------------------------------------
# 5. Executaveis nao assinados em locais incomuns
# ------------------------------------------------------------
function Verificar-ExecutaveisNaoAssinados {
    Write-Host "Verificando executaveis nao assinados em locais incomuns..." -ForegroundColor Cyan
    $pastasAlvo = @("$env:TEMP", "$env:LOCALAPPDATA\Temp", "$env:APPDATA")

    foreach ($pasta in $pastasAlvo) {
        if (Test-Path $pasta) {
            $exes = Get-ChildItem -Path $pasta -Filter "*.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 50
            foreach ($exe in $exes) {
                $assinatura = Get-AuthenticodeSignature -FilePath $exe.FullName -ErrorAction SilentlyContinue
                if ($assinatura.Status -ne "Valid") {
                    Add-Achado "Executaveis" $exe.FullName "Executavel sem assinatura digital valida, rodando de pasta temporaria" "Media"
                }
            }
        }
    }
}

# ------------------------------------------------------------
# 6. Processos com nome de sistema rodando de local errado
# ------------------------------------------------------------
function Verificar-ProcessosDisfarcados {
    Write-Host "Verificando processos com nomes de sistema em locais incomuns..." -ForegroundColor Cyan
    $nomesSistema = @("svchost.exe", "explorer.exe", "csrss.exe", "winlogon.exe", "lsass.exe", "services.exe")

    foreach ($nome in $nomesSistema) {
        $procs = Get-Process | Where-Object { $_.ProcessName + ".exe" -eq $nome } -ErrorAction SilentlyContinue
        foreach ($p in $procs) {
            try {
                $caminho = $p.Path
                if ($caminho -and $caminho -notmatch "\\Windows\\(System32|SysWOW64)\\") {
                    Add-Achado "Processos" "$nome (PID $($p.Id))" "Processo de sistema rodando de local incomum: $caminho" "Alta"
                }
            } catch { }
        }
    }
}

# ------------------------------------------------------------
# 7. Tarefas agendadas com comandos suspeitos
# ------------------------------------------------------------
function Verificar-TarefasAgendadas {
    Write-Host "Verificando tarefas agendadas suspeitas..." -ForegroundColor Cyan
    try {
        $tarefas = Get-ScheduledTask | Where-Object { $_.State -ne "Disabled" }
        foreach ($t in $tarefas) {
            $acoes = $t.Actions
            foreach ($a in $acoes) {
                $exec = $a.Execute
                $args = $a.Arguments
                if ($exec -match "powershell|mshta|regsvr32|wscript|cscript" -and $args -match "http|-enc|-e ") {
                    Add-Achado "Tarefas Agendadas" "$($t.TaskPath)$($t.TaskName)" "Comando remoto/codificado suspeito: $exec $args" "Alta"
                }
            }
        }
    } catch { }
}

function Executar-ScanCompleto {
    $script:achados = @()
    Write-Host ""
    Verificar-Defender
    Verificar-Persistencia
    Verificar-Hosts
    Verificar-ExtensoesDuplas
    Verificar-ExecutaveisNaoAssinados
    Verificar-ProcessosDisfarcados
    Verificar-TarefasAgendadas
    Write-Host ""
    Write-Host "Varredura concluida." -ForegroundColor Green
}

function Mostrar-Resultados {
    if ($achados.Count -eq 0) {
        Write-Host ""
        Write-Host "Nenhum indicador suspeito encontrado nesta varredura." -ForegroundColor Green
        return
    }

    Write-Host ""
    Line
    Write-Host "INDICADORES ENCONTRADOS: $($achados.Count)" -ForegroundColor Yellow
    Line
    Write-Host ""

    $ordenados = $achados | Sort-Object @{Expression={
        switch ($_.Severidade) { "Alta" {0} "Media" {1} default {2} }
    }}

    foreach ($item in $ordenados) {
        $cor = Cor-Severidade $item.Severidade
        Write-Host "[$($item.Severidade)] " -NoNewline -ForegroundColor $cor
        Write-Host "$($item.Categoria) - $($item.Item)"
        Write-Host "         $($item.Motivo)" -ForegroundColor DarkGray
        Write-Host ""
    }

    $altos = ($achados | Where-Object { $_.Severidade -eq "Alta" }).Count
    if ($altos -gt 0) {
        Write-Host "$altos item(ns) de severidade ALTA encontrados." -ForegroundColor Red
        Write-Host "Recomendado: rode uma verificacao completa do Windows Defender e," -ForegroundColor Yellow
        Write-Host "se tiver duvida sobre algum arquivo especifico, evite executa-lo" -ForegroundColor Yellow
        Write-Host "e considere enviar para analise em virustotal.com antes de decidir." -ForegroundColor Yellow
    }
}

while ($true) {

    Clear-Host
    Line
    Write-Host "            MIX OTIMIZACOES - THREAT SCANNER" -ForegroundColor Green
    Line
    Write-Host ""
    Write-Host "IMPORTANTE - LEIA ANTES DE USAR:" -ForegroundColor Yellow
    Write-Host "Este modulo verifica INDICADORES conhecidos de comprometimento" -ForegroundColor Yellow
    Write-Host "(pastas de inicio suspeitas, arquivos disfarcados, processos" -ForegroundColor Yellow
    Write-Host "fora do lugar, etc). NAO E um antivirus completo, nao tem banco" -ForegroundColor Yellow
    Write-Host "de assinaturas e NAO substitui o Windows Defender. Um resultado" -ForegroundColor Yellow
    Write-Host "'limpo' aqui nao garante ausencia de malware, e um item marcado" -ForegroundColor Yellow
    Write-Host "pode ser falso positivo (programa legitimo com comportamento raro)." -ForegroundColor Yellow
    Write-Host ""

    Line
    Write-Host "[1] Executar Varredura Completa de Indicadores"
    Write-Host "[2] Ver Ultimos Resultados"
    Write-Host "[3] Gerar Relatorio"
    Write-Host "[0] Voltar"
    Write-Host ""

    $op = Read-Host "Escolha"

    switch ($op) {

        "1" {
            Executar-ScanCompleto
            foreach ($a in $achados) {
                Log-Achado "[$($a.Severidade)] $($a.Categoria) - $($a.Item): $($a.Motivo)"
            }
            Mostrar-Resultados
            PauseMenu
        }

        "2" {
            if ($achados.Count -eq 0) {
                Write-Host ""
                Write-Host "Nenhuma varredura foi executada nesta sessao ainda. Use a opcao [1]." -ForegroundColor Yellow
            } else {
                Mostrar-Resultados
            }
            PauseMenu
        }

        "3" {
            if ($achados.Count -eq 0) {
                Write-Host ""
                Write-Host "Execute uma varredura primeiro (opcao 1)." -ForegroundColor Yellow
                PauseMenu
                continue
            }

            $arquivo = "$pastaRelatorios\ThreatScanner_Report_$(Get-Date -Format 'ddMMyyyy_HHmmss').txt"
            $linhas = $achados | ForEach-Object { "  [$($_.Severidade)] $($_.Categoria) - $($_.Item): $($_.Motivo)" }

            @"
==============================
MIX OTIMIZACOES THREAT SCANNER REPORT
$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
==============================

AVISO: Este e um scanner de indicadores heuristicos, nao um
antivirus completo. Nao substitui o Windows Defender.

TOTAL DE INDICADORES: $($achados.Count)

$($linhas -join "`n")

Consulte ThreatScanner_Log.txt para o historico de varreduras.
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