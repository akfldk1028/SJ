@echo off
REM Profile Feature 코드 생성 스크립트

echo =====================================
echo Profile Feature Code Generation
echo =====================================
echo.

cd frontend

echo [1/3] Installing dependencies...
call flutter pub get
echo.

echo [2/3] Running code generation...
call dart run build_runner build --delete-conflicting-outputs
echo.

echo [3/3] Code generation complete!
echo.
echo You can now run the app:
echo   flutter run
echo.

pause
