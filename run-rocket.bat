@echo off
pushd "%~dp0"
title=aaa
set CurrDirName=
for %%* in (.) do set CurrDirName=%%~nx*
title rocket

python win-before-run.py

if exist config.xml (
	unilight.exe
) else (
	unilight.exe -c="config-rocket.xml"
)

if "%1"=="" pause
popd
