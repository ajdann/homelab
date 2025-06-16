# Function to fix line endings and remove empty lines at EOF
function Fix-LineEndings {
    param (
        [string]$content
    )
    # Convert to LF line endings and ensure single newline at EOF
    return ($content -replace "`r`n", "`n").TrimEnd() + "`n"
}

# Function to add document start if missing
function Add-DocumentStart {
    param (
        [string]$content
    )
    if (-not $content.TrimStart().StartsWith("---")) {
        return "---`n" + $content
    }
    return $content
}

# Main script
$yamlFiles = Get-ChildItem -Recurse -Filter "*.yaml"
foreach ($file in $yamlFiles) {
    Write-Host "Processing $($file.FullName)..."
    
    # Read the file
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    
    # Apply fixes
    $content = Fix-LineEndings $content
    $content = Add-DocumentStart $content
    
    # Write back to file
    Set-Content -Path $file.FullName -Value $content -NoNewline -Encoding UTF8
    
    Write-Host "Fixed $($file.FullName)"
} 