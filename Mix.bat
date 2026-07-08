@echo off
chcp 65001 >nul
title Mix Otimizacoes
color 0D
cd /d "%~dp0"

:: ============================================================
::  ELEVA PARA ADMINISTRADOR (se ainda nao estiver)
:: ============================================================
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo Solicitando permissao de Administrador...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:menu
cls
powershell -NoProfile -Command ^
    "Write-Host ''; ^
     Write-Host '  ███╗   ███╗██╗██╗  ██╗' -ForegroundColor Magenta; ^
     Write-Host '  ████╗ ████║██║╚██╗██╔╝' -ForegroundColor Red; ^
     Write-Host '  ██╔████╔██║██║ ╚███╔╝ ' -ForegroundColor Yellow; ^
     Write-Host '  ██║╚██╔╝██║██║ ██╔██╗ ' -ForegroundColor Green; ^
     Write-Host '  ██║ ╚═╝ ██║██║██╔╝ ██╗' -ForegroundColor Cyan; ^
     Write-Host '  ╚═╝     ╚═╝╚═╝╚═╝  ╚═╝' -ForegroundColor Blue; ^
     Write-Host '        O T I M I Z A C O E S' -ForegroundColor Magenta; ^
     Write-Host ''"

echo  ==================================================
echo.
echo   [1] Iniciar Launcher
echo   [2] Criar Ponto de Restauracao
echo   [0] Sair
echo.
set /p opcao="  Escolha uma opcao: "

if "%opcao%"=="1" goto iniciar
if "%opcao%"=="2" goto restaurar
if "%opcao%"=="0" goto sair
goto menu

:: ============================================================
::  INICIAR O LAUNCHER (com telinha de carregamento de 2s)
:: ============================================================
:iniciar
cls
powershell -NoProfile -Command "Write-Host ''; Write-Host '   Carregando Mix Otimizacoes...' -ForegroundColor Cyan; Write-Host ''"
timeout /t 2 /nobreak >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Launcher.ps1"
goto fim

:: ============================================================
::  CRIAR PONTO DE RESTAURACAO (direto do bat, sem abrir o Launcher)
:: ============================================================
:restaurar
cls
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Criar-PontoDeRestauracao.ps1"
goto menu

:sair
echo.
echo  Ate mais!
timeout /t 1 /nobreak >nul
exit /b

:fim
pause >nul
