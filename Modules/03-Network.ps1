# ============================================================
# MIX PREFIX - NETWORK MODULE
# Arquivo: 03-Network.ps1
# Compativel: Windows 10 / 11
# Autor: Mix Prefix
# ============================================================

Clear-Host
$Host.UI.RawUI.WindowTitle = "MIX PREFIX - NETWORK"
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

while ($true) {
    Clear-Host
    Line
    Write-Host "               MIX PREFIX NETWORK" -ForegroundColor Green
    Line
    Write-Host ""
    Write-Host "[1]  Flush DNS"
    Write-Host "[2]  Renovar IP"
    Write-Host "[3]  Reset Winsock"
    Write-Host "[4]  Reset TCP/IP"
    Write-Host "[5]  Ping Cloudflare"
    Write-Host "[6]  Ping Google"
    Write-Host "[7]  Tracert"
    Write-Host "[8]  PathPing"
    Write-Host "[9]  Informacoes da Rede"
    Write-Host "[10] Velocidade da Placa"
    Write-Host "[11] Configuracao IP Completa"
    Write-Host "[12] Manutencao Completa"
    Write-Host "[13] Gerar Relatorio"
    Write-Host "[0]  Voltar"
    Write-Host ""
    $op = Read-Host "Escolha"

    switch ($op) {

        "1" {
            ipconfig /flushdns
            PauseMenu
        }

        "2" {
            ipconfig /release
            ipconfig /renew
            PauseMenu
        }

        "3" {
            if (Confirmar "Isso vai resetar as configuracoes do Winsock. Sera necessario reiniciar o PC.") {
                netsh winsock reset
                Write-Host ""
                Write-Host "Reinicie o computador para aplicar." -ForegroundColor Yellow
            }
            PauseMenu
        }

        "4" {
            if (Confirmar "Isso vai resetar a pilha TCP/IP. Sera necessario reiniciar o PC.") {
                netsh int ip reset
                Write-Host ""
                Write-Host "Reinicie o computador para aplicar." -ForegroundColor Yellow
            }
            PauseMenu
        }

        "5" {
            ping 1.1.1.1 -n 20
            PauseMenu
        }

        "6" {
            ping 8.8.8.8 -n 20
            PauseMenu
        }

        "7" {
            tracert 1.1.1.1
            PauseMenu
        }

        "8" {
            pathping 1.1.1.1
            PauseMenu
        }

        "9" {
            Get-NetIPConfiguration | Format-List
            PauseMenu
        }

        "10" {
            Get-NetAdapter | Select-Object Name, Status, LinkSpeed | Format-Table -AutoSize
            PauseMenu
        }

        "11" {
            ipconfig /all
            PauseMenu
        }

        "12" {
            if (Confirmar "Isso vai executar Flush DNS, Renovar IP, Reset Winsock e Reset TCP/IP. Sera necessario reiniciar o PC.") {
                Write-Host ""
                Write-Host "Executando manutencao..."
                ipconfig /flushdns
                ipconfig /release
                ipconfig /renew
                netsh winsock reset
                netsh int ip reset
                Write-Host ""
                Write-Host "Concluido." -ForegroundColor Green
                Write-Host "Reinicie o computador para aplicar tudo." -ForegroundColor Yellow
            }
            PauseMenu
        }

        "13" {
            $adapter = Get-NetAdapter | Where-Object Status -eq "Up" | Select-Object -First 1
            $ip = Get-NetIPAddress -AddressFamily IPv4 |
                Where-Object { $_.IPAddress -notlike "169.*" -and $_.IPAddress -ne "127.0.0.1" } |
                Select-Object -First 1
            $dns = Get-DnsClientServerAddress -AddressFamily IPv4 | Where-Object { $_.ServerAddresses } | Select-Object -First 1
            $gateway = (Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Select-Object -First 1).NextHop

            $arquivo = "$pastaRelatorios\Network_Report_$(Get-Date -Format 'ddMMyyyy_HHmmss').txt"

            @"
==============================
MIX PREFIX NETWORK REPORT
$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')
==============================

Adaptador........: $($adapter.Name)
Status...........: $($adapter.Status)
Velocidade.......: $($adapter.LinkSpeed)
IPv4.............: $($ip.IPAddress)
Gateway..........: $gateway
DNS..............: $($dns.ServerAddresses -join ", ")
"@ | Out-File $arquivo -Encoding UTF8

            Write-Host ""
            Write-Host "Relatorio salvo em: $arquivo" -ForegroundColor Green
            PauseMenu
        }

        "0" {
            break
        }

        Default {
            Write-Host "Opcao invalida." -ForegroundColor Red
            PauseMenu
        }
    }
}