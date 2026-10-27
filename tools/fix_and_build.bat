@echo off
REM ============================================================
REM  Habesha Hub - repair Gradle, test-install on phone, build for Google Play
REM  Double-click this file (or run: tools\fix_and_build.bat)
REM  Everything is written to tools\build_log.txt so Claude can read it.
REM ============================================================
cd /d "%~dp0.."
set LOG=%~dp0build_log.txt
echo Habesha Hub build %date% %time% > "%LOG%"

echo [1/7] Stopping Gradle...
pushd android
call gradlew.bat --stop >> "%LOG%" 2>&1
popd

echo [2/7] Deleting the broken Gradle cache (it is downloaded again)...
if exist "%USERPROFILE%\.gradle\caches" rmdir /s /q "%USERPROFILE%\.gradle\caches" >> "%LOG%" 2>&1
if exist "android\.gradle" rmdir /s /q "android\.gradle" >> "%LOG%" 2>&1

echo [3/7] flutter clean + pub get...
call flutter clean >> "%LOG%" 2>&1
call flutter pub get >> "%LOG%" 2>&1

echo [4/7] Building test version (APK) - first time takes 5-15 minutes...
echo ===== BUILD APK ===== >> "%LOG%"
call flutter build apk --release >> "%LOG%" 2>&1
if errorlevel 1 goto failed

echo [5/7] Installing on the connected phone...
echo ===== INSTALL ===== >> "%LOG%"
call flutter install >> "%LOG%" 2>&1

echo [6/7] Building Google Play version (AAB)...
echo ===== BUILD AAB ===== >> "%LOG%"
call flutter build appbundle --release >> "%LOG%" 2>&1
if errorlevel 1 goto failed

echo [7/7] Free disk space:
echo ===== DONE ===== >> "%LOG%"
powershell -NoProfile -Command "Get-PSDrive C | Format-Table Name,@{n='FreeGB';e={[math]::Round($_.Free/1GB,1)}}" >> "%LOG%" 2>&1
echo.
echo  DONE. The app is installed on your phone.
echo  Google Play file: build\app\outputs\bundle\release\app-release.aab
echo  Tell Claude "ferdig".
pause
exit /b 0

:failed
echo ===== FAILED ===== >> "%LOG%"
echo.
echo  BUILD FAILED. Tell Claude "feil" - Claude reads tools\build_log.txt and fixes it.
pause
exit /b 1
