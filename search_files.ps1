# Find files containing the image.png error
$errorMessage = 'ERROR: Cannot read "image.png" (this model does not support image input)'
$found = @()

$searchPaths = @(
    "$pwd"
)

for ($i = 0; $i -lt $searchPaths.Count; $i++) {
    $path = $searchPaths[$i]
    if (Test-Path $path) {
        $files = Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue
        $dartFiles = $files | Where-Object { $_.Extension -in @('.dart', '.py', '.js', '.ts') }
        
        foreach ($file in $dartFiles) {
            try {
                $content = Get-Content -Path $file.FullName -Raw -ErrorAction SilentlyContinue
                if ($content -and $content -match [regex]::Escape($errorMessage)) {
                    $found += $file.FullName
                    Write-Host "Found in: $($file.FullName)"
                }
            } catch {
                # Skip unreadable files
            }
        }
    }
}

if ($found.Count -eq 0) {
    Write-Host "No files found containing the error message"
} else {
    Write-Host "Total files found: $($found.Count)"
}