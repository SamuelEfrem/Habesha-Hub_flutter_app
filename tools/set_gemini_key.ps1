# ═══════════════════════════════════════════════════════════
# Reads the Gemini key from lib\config\secrets.dart and stores it
# as the Cloud Functions secret GEMINI_KEY, then redeploys.
# The key is never printed.
#   powershell -ExecutionPolicy Bypass -File .\tools\set_gemini_key.ps1
# ═══════════════════════════════════════════════════════════
Set-Location (Join-Path $PSScriptRoot "..")   # run from the project root
$src = Get-Content -Raw "lib\config\secrets.dart"
$m = [regex]::Match($src, "geminiKey\s*=\s*['""]([^'""]+)['""]")
if (-not $m.Success) { Write-Host "Could not find geminiKey in lib\config\secrets.dart" -ForegroundColor Red; exit 1 }
$key = $m.Groups[1].Value.Trim()
Write-Host ("Found key: " + $key.Substring(0,4) + "..." + $key.Substring($key.Length-4) + "  (" + $key.Length + " characters)")

# write without BOM and without newline
[System.IO.File]::WriteAllText("$PWD\gemini_key.txt", $key, (New-Object System.Text.UTF8Encoding($false)))
firebase functions:secrets:set GEMINI_KEY --data-file gemini_key.txt --force
Remove-Item gemini_key.txt

$env:FUNCTIONS_DISCOVERY_TIMEOUT = "60"
firebase deploy --only functions:aiChat

Write-Host ""
Write-Host "Testing..." -ForegroundColor Yellow
try {
  $r = Invoke-RestMethod -Method Post -Uri "https://europe-west1-habesha-hub-7bd1d.cloudfunctions.net/aiChat" `
       -ContentType "application/json" -Body '{"lang":"English","history":[],"text":"hello"}'
  Write-Host ("AI works: " + $r.reply) -ForegroundColor Green
} catch {
  Write-Host ("Still failing: " + $_.ErrorDetails.Message) -ForegroundColor Red
}
