$destDir = "D:\Projek\app-mobile-loker\assets\screenshots"
if (!(Test-Path $destDir)) {
    New-Item -ItemType Directory -Path $destDir -Force | Out-Null
}

$output = & flutter test test/capture_screens_test.dart
$count = 0

foreach ($line in $output) {
    if ($line -match '^CAPTURE_EXPORT:(?<name>.+?):(?<b64>.+)$') {
        $name = $Matches['name']
        $b64 = $Matches['b64']
        $bytes = [System.Convert]::FromBase64String($b64)
        $targetFile = "$destDir\$name"
        [System.IO.File]::WriteAllBytes($targetFile, $bytes)
        Write-Host "Exported: $targetFile ($($bytes.Length) bytes)"
        $count++
    }
}

Write-Host "Done! Successfully exported $count screenshots to $destDir"
