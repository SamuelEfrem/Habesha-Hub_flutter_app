@echo off
REM Deploys the website, Firestore rules and Storage rules for Habesha Hub
cd /d "%~dp0.."
set FUNCTIONS_DISCOVERY_TIMEOUT=60
echo Deploying Habesha Hub (hosting, firestore rules, storage rules)...
call firebase deploy --only "hosting,firestore:rules,storage" > tools\deploy_log.txt 2>&1
type tools\deploy_log.txt
echo.
echo Done. You can close this window.
pause
