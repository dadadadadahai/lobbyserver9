@echo off
pushd "%~dp0"
title=aaa
set CurrDirName=
for %%* in (.) do set CurrDirName=%%~nx*
title longhu

python win-before-run.py

if exist config.xml (
	unilight.exe
) else (
	unilight.exe -c="config-LongHu.xml"
)

if "%1"=="" pause
popd
