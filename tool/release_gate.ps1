param(
  [switch]$SkipTests,
  [switch]$BuildDebugApk
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
Push-Location $projectRoot

function Assert-LastExitCode([string]$step) {
  if ($LASTEXITCODE -ne 0) {
    throw "$step failed with exit code $LASTEXITCODE."
  }
}

try {
  Write-Host '1/5 Resolving locked dependencies...'
  flutter pub get
  Assert-LastExitCode 'Dependency resolution'

  Write-Host '2/5 Verifying formatting...'
  dart format --output=none --set-exit-if-changed lib test integration_test
  Assert-LastExitCode 'Formatting verification'

  Write-Host '3/5 Running static analysis...'
  flutter analyze
  Assert-LastExitCode 'Static analysis'

  if (-not $SkipTests) {
    Write-Host '4/5 Running automated tests...'
    flutter test --no-pub
    Assert-LastExitCode 'Automated tests'
  } else {
    Write-Host '4/5 Tests skipped by explicit flag.'
  }

  if ($BuildDebugApk) {
    Write-Host '5/5 Building installable Android debug APK...'
    flutter build apk --debug --no-pub
    Assert-LastExitCode 'Android debug build'
  } else {
    Write-Host '5/5 Build skipped. Add -BuildDebugApk for a local artifact.'
  }

  Write-Host 'Release gate passed.' -ForegroundColor Green
} finally {
  Pop-Location
}
