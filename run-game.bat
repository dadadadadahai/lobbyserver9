@echo off
pushd "%~dp0"
title=aaa
set CurrDirName=
for %%* in (.) do set CurrDirName=%%~nx*
title game

python win-before-run.py


unilight.exe -c="config-game.xml"


if "%1"=="" pause
popd
