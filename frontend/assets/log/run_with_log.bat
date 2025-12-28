@echo off
chcp 65001 >nul
cd /d D:\Data\20_Flutter\01_SJ\frontend
D:\development\flutter\bin\flutter.bat run -d chrome --web-port=7777 2>&1 | tee D:\Data\20_Flutter\01_SJ\frontend\assets\log\%date:~0,4%-%date:~5,2%-%date:~8,2%.txt
