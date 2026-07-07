@echo off
title OTIMIZACAO MIX - FRAMETIME
color 0A

echo ==========================================
echo          OTIMIZACAO MIX
echo ==========================================

echo [20%%] Melhorando scheduler...
bcdedit /set disabledynamictick yes >nul

echo [40%%] Melhorando sincronizacao...
bcdedit /set tscsyncpolicy Enhanced >nul

echo [60%%] Melhorando prioridade de jogos...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v SchedulingCategory /t REG_SZ /d High /f >nul

echo [80%%] Melhorando GPU priority...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f >nul

echo [100%%] Finalizado...
pause