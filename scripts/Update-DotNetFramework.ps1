# Update .NET Framework Script
# This script updates all .csproj files from unsupported .NET Core 3.0/3.1 to .NET 6.0

Write-Host "🔧 Updating .NET Framework versions..." -ForegroundColor Green

# Get all .csproj files in the GrpcDemos-master directory
$projectFiles = Get-ChildItem -Path "GrpcDemos-master" -Filter "*.csproj" -Recurse

$updatedCount = 0
$totalCount = $projectFiles.Count

Write-Host "Found $totalCount project files to update" -ForegroundColor Yellow

foreach ($file in $projectFiles) {
    $content = Get-Content $file.FullName -Raw
    $originalContent = $content
    
    # Update netcoreapp3.0 to net6.0
    $content = $content -replace '<TargetFramework>netcoreapp3\.0</TargetFramework>', '<TargetFramework>net6.0</TargetFramework>'
    
    # Update netcoreapp3.1 to net6.0
    $content = $content -replace '<TargetFramework>netcoreapp3\.1</TargetFramework>', '<TargetFramework>net6.0</TargetFramework>'
    
    # Only write if content changed
    if ($content -ne $originalContent) {
        Set-Content -Path $file.FullName -Value $content -NoNewline
        Write-Host "✅ Updated: $($file.Name)" -ForegroundColor Green
        $updatedCount++
    } else {
        Write-Host "⏭️  Skipped: $($file.Name) (already up to date)" -ForegroundColor Gray
    }
}

Write-Host "`n🎉 Update Complete!" -ForegroundColor Green
Write-Host "Updated $updatedCount out of $totalCount project files" -ForegroundColor Cyan
Write-Host "All projects now target .NET 6.0 (LTS)" -ForegroundColor Cyan

# Verify the updates
Write-Host "`n🔍 Verifying updates..." -ForegroundColor Yellow
$remainingOldFrameworks = Get-ChildItem -Path "GrpcDemos-master" -Filter "*.csproj" -Recurse | 
    Select-String -Pattern "netcoreapp3\.[01]" | 
    Measure-Object | 
    Select-Object -ExpandProperty Count

if ($remainingOldFrameworks -eq 0) {
    Write-Host "✅ All project files successfully updated to .NET 6.0" -ForegroundColor Green
} else {
    Write-Host "⚠️  $remainingOldFrameworks project files still contain old framework references" -ForegroundColor Red
}

Write-Host "`n📋 Next Steps:" -ForegroundColor Yellow
Write-Host "1. Test the solution by building it" -ForegroundColor White
Write-Host "2. Update any Docker files if present" -ForegroundColor White
Write-Host "3. Update CI/CD pipelines to use .NET 6.0" -ForegroundColor White
Write-Host "4. Commit and push changes to resolve GitHub warnings" -ForegroundColor White
