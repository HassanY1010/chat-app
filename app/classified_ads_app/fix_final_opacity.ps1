# Fix all remaining withOpacity issues
Write-Host "Fixing all remaining withOpacity issues..."

# Fix delete_ad_screen.dart line 1210
$file = "lib\screens\delete_ad_screen.dart"
if (Test-Path $file) {
    $content = Get-Content $file -Raw
    $content = $content -replace 'Colors\.black\.withOpacity\(0\.03\)', 'Colors.black.withAlpha(8)'
    Set-Content -Path $file -Value $content
    Write-Host "Fixed: $file"
}

# Fix register_screen.dart line 1139
$file = "lib\screens\register_screen.dart"
if (Test-Path $file) {
    $content = Get-Content $file -Raw
    $content = $content -replace '\.withOpacity\(0\.15 \+ 0\.05 \* math\.sin\(animation\.value \* 2 \* math\.pi\)\)', '.withAlpha((int)((0.15 + 0.05 * math.sin(animation.value * 2 * math.pi)) * 255))'
    Set-Content -Path $file -Value $content
    Write-Host "Fixed: $file"
}

# Fix login_screen.dart lines 654, 670-671
$file = "lib\screens\login_screen.dart"
if (Test-Path $file) {
    $content = Get-Content $file -Raw
    $content = $content -replace '\.withOpacity\(0\.25 \+ 0\.1 \* math\.sin\(animation\.value \* 2 \* math\.pi\)\)', '.withAlpha((int)((0.25 + 0.1 * math.sin(animation.value * 2 * math.pi)) * 255))'
    $content = $content -replace 'Colors\.white\.withOpacity\(0\.05 \* \(1 - animation\.value\)\)', 'Colors.white.withAlpha((int)(0.05 * (1 - animation.value) * 255))'
    $content = $content -replace 'Colors\.white\.withOpacity\(0\.02 \* \(1 - animation\.value\)\)', 'Colors.white.withAlpha((int)(0.02 * (1 - animation.value) * 255))'
    Set-Content -Path $file -Value $content
    Write-Host "Fixed: $file"
}

# Fix favorites_screen.dart line 880
$file = "lib\screens\favorites_screen.dart"
if (Test-Path $file) {
    $content = Get-Content $file -Raw
    $content = $content -replace 'Colors\.black\.withOpacity\(0\.03\)', 'Colors.black.withAlpha(8)'
    Set-Content -Path $file -Value $content
    Write-Host "Fixed: $file"
}

Write-Host "`nAll withOpacity issues fixed!"
Write-Host "Running flutter analyze to verify..."
