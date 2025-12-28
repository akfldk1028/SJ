$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$logFile = "D:\Data\20_Flutter\01_SJ\frontend\assets\log\2025-12-28.txt"

Set-Location "D:\Data\20_Flutter\01_SJ\frontend"

& D:\development\flutter\bin\flutter.bat run -d chrome --web-port=7777 2>&1 | Tee-Object -FilePath $logFile -Append
