@echo off
REM ============================================================
REM MenuSuporte.bat — Wrapper para executar MenuSuporte.ps1
REM v4.3 — Execução Direta do Script Único Integrado Monolítico
REM ============================================================

setlocal enabledelayedexpansion

REM ── Valida privilégios de Administrador ─────────────────────
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo  ================================================
    echo  ERRO: Privilégios de Administrador necessários!
    echo  ================================================
    echo.
    echo  Clique com o botão direito e selecione: "Executar como Administrador"
    echo.
    pause
    exit /b 1
)

REM ── Define a localização do script integrado unificado ──────
set "SCRIPT_NAME=MenuSuporte.ps1"
set "SCRIPT_PATH=%~dp0%SCRIPT_NAME%"

REM ── Seleção Automática de Diretório de Trabalho ─────────────
echo %~dp0 | findstr /i "C:" >nul
if %errorlevel% == 0 (
    set "PASTA_MODO=C:\Suporte"
    set "MODO_LABEL=SISTEMA LOCAL (C:\Suporte)"
) else (
    set "PASTA_MODO=%~dp0SuporteData"
    set "MODO_LABEL=PENDRIVE AUTOMÁTICO (Ferramentas)"
)

REM ── Cria a pasta de trabalho caso ela não exista ──────────
if not exist "%PASTA_MODO%" (
    mkdir "%PASTA_MODO%" 2>nul
)

REM ── Inicialização e Injeção no PowerShell ──────────────────
cls
echo.
echo  ==========================================================
echo  =    TECMASTERY — MenuSuporte -Desenvolvido por Pablo    =
echo  ==========================================================
echo.
echo   Computador  : %COMPUTERNAME%
echo   Modo        : %MODO_LABEL%
echo   Script Alvo : %SCRIPT_NAME%
echo.
echo  ============================================================
echo.
timeout /t 1 /nobreak >nul

REM ── Dispara o script único com bypass de políticas ──────────
if not exist "%SCRIPT_PATH%" (
    echo.
    echo  ============================================================
    echo  ERRO: Script nao encontrado em:
    echo  %SCRIPT_PATH%
    echo.
    echo  Coloque MenuSuporte.ps1 na mesma pasta do BAT.
    echo  ============================================================
    echo.
    pause
    exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_PATH%" -PastaBase "%PASTA_MODO%"

set "EXITCODE=%ERRORLEVEL%"
if %EXITCODE% neq 0 (
    echo.
    echo  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    echo  AVISO: O script retornou código de erro: %EXITCODE%
    echo  !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    echo.
    pause
)
exit /b %EXITCODE%
