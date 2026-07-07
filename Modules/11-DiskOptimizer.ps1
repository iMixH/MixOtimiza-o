# ============================================================
# MIX OTIMIZACOES - DISK OPTIMIZER MODULE
# Arquivo: 11-DiskOptimizer.ps1
# ============================================================

Clear-Host
$Host.UI.RawUI.WindowTitle = "MIX OTIMIZACOES - DISK OPTIMIZER"
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
    $logFile = "$pastaRelatorios\DiskOptimizer_Log.txt"
    "$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') - $texto" | Out-File $logFile -Append -Encoding UTF8
}

while ($true) {

    Clear-Host
    Line
    Write-Host "            MIX OTIMIZACOES - DISK OPTIMIZER" -ForegroundColor Green
    Line
    Write-Host ""

    $disco = Get-PhysicalDisk | Select-Object -First 1
    $volC = Get-Volume -DriveLetter C -ErrorAction SilentlyContinue
    $tipo = $disco.MediaType

    Write-Host "Disco Detectado..: $($disco.FriendlyName)"
    Write-Host "Tipo..............: $tipo"
    if ($volC) {
        $livre = [math]::Round($volC.SizeRemaining / 1GB, 2)
        $total = [math]::Round($volC.Size / 1GB, 2)
        Write-Host "Espaco Livre......: $livre GB / $total GB"
    }
    Write-Host ""

    if ($tipo -eq "SSD") {
        Write-Host "Seu disco e um SSD: desfragmentacao NAO e recomendada," -ForegroundColor Yellow
        Write-Host "pois reduz a vida util. Use TRIM em vez disso." -ForegroundColor Yellow
        Write-Host ""
    }

    Line
    Write-Host "[1] Ver Saude do Disco (SMART)"
    Write-Host "[2] Rodar TRIM (recomendado para SSD)"
    Write-Host "[3] Desfragmentar Disco (recomendado apenas para HDD)"
    Write-Host "[4] Agendar Verificacao de Erros (CHKDSK)"
    Write-Host "[5] Analisar Maiores Pastas em C:"
    Write-Host "[6] Ver Espaco Usado por Categoria (WinSxS, Usuarios, etc)"
    Write-Host "[7] Gerar Relatorio"
    Write-Host "[0] Voltar"
    Write-Host ""

    $op = Read-Host "Escolha"

    switch ($op) {

        "1" {
            Write-Host ""
            Write-Host "Consultando saude do disco..." -ForegroundColor Cyan
            try {
                $smart = Get-PhysicalDisk | Select-Object FriendlyName, MediaType, HealthStatus, OperationalStatus
                $smart | Format-List

                $vidaUtil = Get-CimInstance -Namespace "root\wmi" -ClassName MSStorageDriver_FailurePredictStatus -ErrorAction SilentlyContinue
                if ($vidaUtil) {
                    foreach ($v in $vidaUtil) {
                        $status = if ($v.PredictFailure) { "ATENCAO: Falha Prevista" } else { "Normal" }
                        Write-Host "Status de Falha: $status" -ForegroundColor $(if ($v.PredictFailure) { "Red" } else { "Green" })
                    }
                }
            } catch {
                Write-Host "Nao foi possivel obter dados SMART detalhados neste sistema." -ForegroundColor Yellow
            }
            PauseMenu
        }

        "2" {
            if (Confirmar "Isso vai executar o TRIM/Otimizacao no disco C:. Processo rapido e seguro para SSD.") {
                Write-Host ""
                Write-Host "Executando otimizacao..." -ForegroundColor Cyan
                Optimize-Volume -DriveLetter C -ReTrim -Verbose -ErrorAction SilentlyContinue
                Log-Alteracao "TRIM executado no disco C:"
                Write-Host ""
                Write-Host "TRIM concluido." -ForegroundColor Green
            }
            PauseMenu
        }

        "3" {
            if ($tipo -eq "SSD") {
                Write-Host ""
                Write-Host "Este disco e um SSD. Desfragmentar SSD NAO melhora performance" -ForegroundColor Red
                Write-Host "e reduz a vida util do disco. Operacao bloqueada por seguranca." -ForegroundColor Red
                PauseMenu
                continue
            }
            if (Confirmar "Isso vai desfragmentar o disco C:. Pode demorar bastante dependendo do tamanho.") {
                Write-Host ""
                Write-Host "Desfragmentando... isso pode levar varios minutos." -ForegroundColor Cyan
                Optimize-Volume -DriveLetter C -Defrag -Verbose -ErrorAction SilentlyContinue
                Log-Alteracao "Desfragmentacao executada no disco C:"
                Write-Host ""
                Write-Host "Desfragmentacao concluida." -ForegroundColor Green
            }
            PauseMenu
        }

        "4" {
            if (Confirmar "Isso vai agendar uma verificacao de erros (CHKDSK) no proximo reinicio do PC.") {
                cmd /c "echo Y| chkdsk C: /f /r" | Out-Null
                Log-Alteracao "CHKDSK agendado para o disco C: no proximo boot"
                Write-Host ""
                Write-Host "CHKDSK agendado. Sera executado no proximo reinicio." -ForegroundColor Green
                Write-Host "Reinicie o PC quando for conveniente." -ForegroundColor Yellow
            }
            PauseMenu
        }

        "5" {
            Write-Host ""
            Write-Host "Analisando maiores pastas em C:\Users\$env:USERNAME ..." -ForegroundColor Cyan
            Write-Host "(isso pode levar alguns instantes)" -ForegroundColor DarkGray
            Write-Host ""
            $pastaUsuario = "$env:USERPROFILE"
            Get-ChildItem $pastaUsuario -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                $tamanho = (Get-ChildItem $_.FullName -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
                [PSCustomObject]@{
                    Pasta = $_.Name
                    TamanhoGB = [math]::Round($tamanho / 1GB, 2)
                }
            } | Sort-Object TamanhoGB -Descending | Select-Object -First 10 | Format-Table -AutoSize
            PauseMenu
        }

        "6" {
            Write-Host ""
            Write-Host "Espaco usado por categoria (estimativa):" -ForegroundColor Cyan
            Write-Host ""
            $winSxS = (Get-ChildItem "$env:windir\WinSxS" -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
            $usuarios = (Get-ChildItem "C:\Users" -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
            $programas = (Get-ChildItem "C:\Program Files","C:\Program Files (x86)" -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum

            Write-Host "WinSxS (componentes do sistema)..: $([math]::Round($winSxS/1GB,2)) GB"
            Write-Host "Pastas de Usuarios................: $([math]::Round($usuarios/1GB,2)) GB"
            Write-Host "Programas Instalados...............: $([math]::Round($programas/1GB,2)) GB"
            PauseMenu
        }

        "7" {
            $arquivo = "$pastaRelatorios\DiskOptimizer_Report_$(Get-Date -Format 'ddMMyyyy_HHmmss').txt"

            @"
==============================
MIX OTIMIZACOES DISK OPTIMIZER REPORT
$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
==============================

Disco............: $($disco.FriendlyName)
Tipo.............: $tipo
Espaco Livre.....: $(if($volC){[math]::Round($volC.SizeRemaining/1GB,2)}else{"N/D"}) GB
Espaco Total.....: $(if($volC){[math]::Round($volC.Size/1GB,2)}else{"N/D"}) GB

Consulte DiskOptimizer_Log.txt para o historico de operacoes executadas.
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