@echo off
pushd "%~dp0"
title=aaa
set CurrDirName=
for %%* in (.) do set CurrDirName=%%~nx*
title worldcup

python win-before-run.py

if exist config.xml (
	unilight.exe
) else (
	unilight.exe -c="config-worldcup.xml"
)

if "%1"=="" pause
popd
