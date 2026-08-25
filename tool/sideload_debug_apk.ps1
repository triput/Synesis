# Sideload the debug APK with adb install -r (keeps app data; see DEF-067).
# Run from repo root, tool/, or via Cursor: Tasks → "Synesis: Sideload debug APK".

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$apk = Join-Path $repoRoot "build\app\outputs\flutter-apk\app-debug.apk"

if (-not (Test-Path -LiteralPath $apk)) {
    Write-Error @"
APK not found:
  $apk

Build first:
  flutter build apk --debug --dart-define-from-file=oauth_local.json
"@
}

Write-Host "Sideloading (install -r, no uninstall):" -ForegroundColor Cyan
Write-Host "  $apk"
adb install -r $apk
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}
Write-Host "Installed." -ForegroundColor Green
