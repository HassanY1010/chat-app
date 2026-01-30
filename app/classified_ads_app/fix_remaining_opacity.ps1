$files = @('my_ads_screen.dart', 'profile_screen.dart', 'register_screen.dart')

foreach ($file in $files) {
    $path = "lib\screens\$file"
    if (Test-Path $path) {
        $content = Get-Content $path -Raw
        
        # Fix all remaining withOpacity instances
        $content = $content -replace '\.withOpacity\(0\.02\)', '.withAlpha(5)'
        $content = $content -replace '\.withOpacity\(0\.03\)', '.withAlpha(8)'
        $content = $content -replace '\.withOpacity\(0\.04\)', '.withAlpha(10)'
        $content = $content -replace '\.withOpacity\(0\.05\)', '.withAlpha(13)'
        $content = $content -replace '\.withOpacity\(0\.08\)', '.withAlpha(20)'
        $content = $content -replace '\.withOpacity\(0\.1\)', '.withAlpha(26)'
        $content = $content -replace '\.withOpacity\(0\.15\)', '.withAlpha(38)'
        $content = $content -replace '\.withOpacity\(0\.2\)', '.withAlpha(51)'
        $content = $content -replace '\.withOpacity\(0\.3\)', '.withAlpha(77)'
        $content = $content -replace '\.withOpacity\(0\.4\)', '.withAlpha(102)'
        $content = $content -replace '\.withOpacity\(0\.5\)', '.withAlpha(128)'
        $content = $content -replace '\.withOpacity\(0\.6\)', '.withAlpha(153)'
        $content = $content -replace '\.withOpacity\(0\.7\)', '.withAlpha(179)'
        $content = $content -replace '\.withOpacity\(0\.8\)', '.withAlpha(204)'
        $content = $content -replace '\.withOpacity\(0\.9\)', '.withAlpha(230)'
        $content = $content -replace '\.withOpacity\(0\.95\)', '.withAlpha(242)'
        $content = $content -replace '\.withOpacity\(0\.98\)', '.withAlpha(250)'
        
        Set-Content -Path $path -Value $content
        Write-Host "Fixed: $file"
    }
}

Write-Host "All remaining files processed!"
