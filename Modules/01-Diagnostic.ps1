# ============================================================
# MIX PREFIX - DIAGNOSTIC MODULE
# Arquivo: 01-Diagnostic.ps1
# Compativel: Windows 10 / 11
# Autor: Mix Prefix
# ============================================================

Clear-Host
$ErrorActionPreference = "SilentlyContinue"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "         MIX PREFIX DIAGNOSTIC"
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Coleta de dados
$cpu   = Get-CimInstance Win32_Processor
$gpu   = Get-CimInstance Win32_VideoController | Select-Object -First 1
$ram   = Get-CimInstance Win32_ComputerSystem
$os    = Get-CimInstance Win32_OperatingSystem
$disk  = Get-PhysicalDisk | Select-Object -First 1
$diskLogic = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'"
$board = Get-CimInstance Win32_BaseBoard

$totalRam = [math]::Round($ram.TotalPhysicalMemory / 1GB, 2)
$freeDisk = if ($diskLogic) { [math]::Round($diskLogic.FreeSpace / 1GB, 2) } else { "N/D" }
$totalDisk = if ($diskLogic) { [math]::Round($diskLogic.Size / 1GB, 2) } else { "N/D" }

# Monta as linhas do relatorio (usadas para tela e arquivo)
$linhas = @()
$linhas += "=========================================="
$linhas += "         MIX PREFIX DIAGNOSTIC"
$linhas += "         $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
$linhas += "=========================================="
$linhas += ""
$linhas += "CPU.............: $($cpu.Name)"
$linhas += "Nucleos.........: $($cpu.NumberOfCores)"
$linhas += "Threads.........: $($cpu.NumberOfLogicalProcessors)"
$linhas += ""
$linhas += "GPU.............: $($gpu.Name)"
$linhas += ""
$linhas += "RAM Total.......: $totalRam GB"
$linhas += ""
$linhas += "Placa-mae.......: $($board.Manufacturer) $($board.Product)"
$linhas += ""
$linhas += "Windows.........: $($os.Caption)"
$linhas += "Versao Build....: $($os.BuildNumber)"
$linhas += ""
$linhas += "Disco...........: $($disk.FriendlyName)"
$linhas += "Tipo............: $($disk.MediaType)"
$linhas += "Espaco Livre C:.: $freeDisk GB / $totalDisk GB"
$linhas += ""
$linhas += "=========================================="
$linhas += "Relatorio concluido."
$linhas += "=========================================="

# Exibe na tela
$linhas | ForEach-Object { Write-Host $_ }

# Salva o relatorio em .txt na area de trabalho
$pasta = "$env:USERPROFILE\Desktop\MixPrefix_Relatorios"
if (-not (Test-Path $pasta)) { New-Item -ItemType Directory -Path $pasta | Out-Null }
$arquivo = "$pasta\Diagnostico_$(Get-Date -Format 'ddMMyyyy_HHmmss').txt"
$linhas | Out-File -FilePath $arquivo -Encoding UTF8

Write-Host ""
Write-Host "Relatorio salvo em: $arquivo" -ForegroundColor Green
Write-Host ""
Read-Host "Pressione ENTER para voltar ao menu"