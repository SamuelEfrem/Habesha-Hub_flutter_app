# ═══════════════════════════════════════════════════════════
# Habesha Hub — stop tracking secret files in git
# Run in PowerShell from the project folder:
#   powershell -ExecutionPolicy Bypass -File .\tools\fix_secrets.ps1
# The files stay on your PC — git just stops following them.
# ═══════════════════════════════════════════════════════════
Set-Location (Join-Path $PSScriptRoot "..")   # run from the project root
$files = @(
  "habesha-hub.jks",
  "serviceAccountKey.json",
  ".bunny-keys.json",
  "lib/config/secrets.dart"
) + (git ls-files "*firebase-adminsdk*.json")

foreach ($f in $files) {
  if ($f -and (git ls-files --error-unmatch $f 2>$null)) {
    git rm --cached --quiet -- $f
    Write-Host "Removed from git: $f" -ForegroundColor Green
  }
}

git add .gitignore
git commit -m "Stop tracking secret keys and keystore"
Write-Host ""
Write-Host "Done. Now create NEW keys (see instructions in the chat) and delete the old ones." -ForegroundColor Yellow
