# GitHub Reviewer Setup Script
# Run this script to quickly set up the code review system

Write-Host "🔧 Setting up GitHub Code Review System..." -ForegroundColor Green

# Get GitHub username
$githubUsername = Read-Host "Enter your GitHub username (e.g., john-doe)"

if ([string]::IsNullOrWhiteSpace($githubUsername)) {
    Write-Host "❌ GitHub username is required!" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Using GitHub username: $githubUsername" -ForegroundColor Green

# Update CODEOWNERS file
Write-Host "📝 Updating CODEOWNERS file..." -ForegroundColor Yellow

$codeownersPath = ".github/CODEOWNERS"
if (Test-Path $codeownersPath) {
    $content = Get-Content $codeownersPath -Raw
    $content = $content -replace "YOUR_GITHUB_USERNAME", $githubUsername
    Set-Content $codeownersPath $content
    Write-Host "✅ CODEOWNERS updated with your username" -ForegroundColor Green
} else {
    Write-Host "❌ CODEOWNERS file not found!" -ForegroundColor Red
}

# Update workflow files to use the username
Write-Host "📝 Updating workflow files..." -ForegroundColor Yellow

# Update auto-pull-request.yml
$autoPrPath = ".github/workflows/auto-pull-request.yml"
if (Test-Path $autoPrPath) {
    $content = Get-Content $autoPrPath -Raw
    $content = $content -replace "@your-username", "@$githubUsername"
    Set-Content $autoPrPath $content
    Write-Host "✅ Auto PR workflow updated" -ForegroundColor Green
}

# Update assign-reviewers.yml
$assignReviewersPath = ".github/workflows/assign-reviewers.yml"
if (Test-Path $assignReviewersPath) {
    $content = Get-Content $assignReviewersPath -Raw
    $content = $content -replace "@your-username", "@$githubUsername"
    Set-Content $assignReviewersPath $content
    Write-Host "✅ Reviewer assignment workflow updated" -ForegroundColor Green
}

Write-Host ""
Write-Host "🎉 Setup Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Commit and push these changes to GitHub" -ForegroundColor White
Write-Host "2. Go to your repository Settings > Branches" -ForegroundColor White
Write-Host "3. Add a branch protection rule for 'main' branch:" -ForegroundColor White
Write-Host "   - ✅ Require a pull request before merging" -ForegroundColor White
Write-Host "   - ✅ Require review from code owners" -ForegroundColor White
Write-Host "   - ✅ Dismiss stale reviews when new commits are pushed" -ForegroundColor White
Write-Host "4. Test by creating a feature branch and pushing changes" -ForegroundColor White
Write-Host ""
Write-Host "🚀 How it works:" -ForegroundColor Cyan
Write-Host "- When you push to any branch except 'main', a PR will be created automatically" -ForegroundColor White
Write-Host "- You will be assigned as the reviewer" -ForegroundColor White
Write-Host "- Code review comments will be generated based on C# guidelines" -ForegroundColor White
Write-Host "- You'll see realistic review comments in the GitHub UI" -ForegroundColor White
Write-Host ""
Write-Host "✅ Ready to use! Make a test commit to see it in action." -ForegroundColor Green
