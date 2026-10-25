# ═══════════════════════════════════════════════════════════
# Habesha Hub — one-time cleanup of the project folder
#   powershell -ExecutionPolicy Bypass -File .\tools\cleanup.ps1
# Safe: only removes old copies, backups and leftovers.
# ═══════════════════════════════════════════════════════════
Set-Location (Join-Path $PSScriptRoot "..")

$remove = @(
  # old script copies (new versions live in tools\)
  "sync_bunny.js", "sync_bunny_photos.js", "translate_services.js", "fix_countries.js",
  "seed_firestore.js", "update_cameraman1_video.js",
  "set_gemini_key.ps1", "fix_secrets.ps1", "cleanup_old_files.ps1",
  # one-off Python helpers from earlier sessions
  "cleanup.py", "redesign_marketplace.py", "add_theme_toggle.py",
  # backups and leftovers
  "backup", "backup_2026-10-25",
  "lib\main.dart.bak", "lib\theme\app_theme.dart.bak",
  "lib\screens\ai_chat_screen.dart.broken",
  "lib\screens\marketplace_screen.dart.bak",
  "lib\screens\placeholder_screens.dart.bak",
  "public\index.html_section.txt",
  # unused Android activities (the app uses no.habesha.hub.MainActivity)
  "android\app\src\main\kotlin\com",
  "android\app\src\main\kotlin\no\habesha\habesha_hub"
)
foreach ($f in $remove) {
  if (Test-Path $f) { Remove-Item -Recurse -Force $f; Write-Host "Deleted: $f" -ForegroundColor Green }
}

# CV does not belong in the app project → move it to your CV folder
if (Test-Path "Samuel_CV_2026_v6.docx") {
  $dest = Join-Path (Resolve-Path "..") "vitnemål og cv"
  if (-not (Test-Path $dest)) { $dest = (Resolve-Path "..").Path }
  Move-Item "Samuel_CV_2026_v6.docx" $dest -Force
  Write-Host "Moved CV to: $dest" -ForegroundColor Green
}
Write-Host "`nCleanup done." -ForegroundColor Yellow
