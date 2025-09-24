# PowerShell script to validate C# code against Microsoft coding guidelines
# This script can be run locally or in CI/CD pipelines

param(
    [string]$ProjectPath = ".",
    [string]$OutputPath = "./validation-results",
    [switch]$IncludeStyleCop = $true,
    [switch]$IncludeSecurityScan = $true,
    [switch]$GenerateReport = $true,
    [switch]$Verbose = $false
)

# Set error action preference
$ErrorActionPreference = "Continue"

# Create output directory
if (!(Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

Write-Host "🔍 C# Code Guidelines Validation Script" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green

# Function to write log messages
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

# Function to check if .NET is installed
function Test-DotNetInstallation {
    try {
        $dotnetVersion = dotnet --version
        Write-Log "✅ .NET SDK found: $dotnetVersion" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "❌ .NET SDK not found. Please install .NET SDK 6.0 or later." "ERROR"
        return $false
    }
}

# Function to restore and build project
function Build-Project {
    param([string]$Path)
    
    Write-Log "🔨 Building project at: $Path"
    
    try {
        # Restore packages
        Write-Log "📦 Restoring NuGet packages..."
        dotnet restore $Path --verbosity quiet
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "❌ Failed to restore packages" "ERROR"
            return $false
        }
        
        # Build project
        Write-Log "🔨 Building project..."
        dotnet build $Path --configuration Release --no-restore --verbosity minimal
        
        if ($LASTEXITCODE -ne 0) {
            Write-Log "❌ Build failed" "ERROR"
            return $false
        }
        
        Write-Log "✅ Build successful" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "❌ Build error: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# Function to run StyleCop analysis
function Invoke-StyleCopAnalysis {
    param([string]$Path)
    
    if (-not $IncludeStyleCop) {
        Write-Log "⏭️  Skipping StyleCop analysis" "WARNING"
        return
    }
    
    Write-Log "🎨 Running StyleCop analysis..."
    
    try {
        # Add StyleCop.Analyzers package if not present
        $csprojFiles = Get-ChildItem -Path $Path -Filter "*.csproj" -Recurse
        
        foreach ($csproj in $csprojFiles) {
            Write-Log "📝 Adding StyleCop.Analyzers to $($csproj.Name)"
            dotnet add $csproj.FullName package StyleCop.Analyzers --version 1.2.0-beta.556 --no-restore
        }
        
        # Run analysis
        $outputFile = Join-Path $OutputPath "stylecop-results.txt"
        dotnet build $Path --configuration Release --no-restore /p:RunAnalyzersDuringBuild=true /p:EnableNETAnalyzers=true 2>&1 | Tee-Object -FilePath $outputFile
        
        Write-Log "✅ StyleCop analysis completed. Results saved to: $outputFile" "SUCCESS"
    }
    catch {
        Write-Log "❌ StyleCop analysis failed: $($_.Exception.Message)" "ERROR"
    }
}

# Function to run security scan
function Invoke-SecurityScan {
    param([string]$Path)
    
    if (-not $IncludeSecurityScan) {
        Write-Log "⏭️  Skipping security scan" "WARNING"
        return
    }
    
    Write-Log "🔒 Running security scan..."
    
    try {
        # Add security analyzers
        $csprojFiles = Get-ChildItem -Path $Path -Filter "*.csproj" -Recurse
        
        foreach ($csproj in $csprojFiles) {
            Write-Log "🔐 Adding security analyzers to $($csproj.Name)"
            dotnet add $csproj.FullName package Microsoft.CodeAnalysis.NetAnalyzers --no-restore
            dotnet add $csproj.FullName package SecurityCodeScan.VS2019 --no-restore
        }
        
        # Run security analysis
        $outputFile = Join-Path $OutputPath "security-results.txt"
        dotnet build $Path --configuration Release --no-restore /p:RunAnalyzersDuringBuild=true /p:EnableNETAnalyzers=true 2>&1 | Tee-Object -FilePath $outputFile
        
        Write-Log "✅ Security scan completed. Results saved to: $outputFile" "SUCCESS"
    }
    catch {
        Write-Log "❌ Security scan failed: $($_.Exception.Message)" "ERROR"
    }
}

# Function to check coding guidelines compliance
function Test-CodingGuidelines {
    param([string]$Path)
    
    Write-Log "📋 Checking coding guidelines compliance..."
    
    $issues = @()
    $csFiles = Get-ChildItem -Path $Path -Filter "*.cs" -Recurse
    
    foreach ($file in $csFiles) {
        $content = Get-Content $file.FullName -Raw
        $lines = Get-Content $file.FullName
        
        # Check for common violations
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            $lineNumber = $i + 1
            
            # Check for missing braces
            if ($line -match '^\s*(if|for|while|foreach)\s*\([^)]+\)\s*[^{]\s*$') {
                $issues += "File: $($file.Name), Line $lineNumber`: Missing braces for control statement"
            }
            
            # Check for hardcoded strings (basic check)
            if ($line -match '"[^"]*password[^"]*"|"[^"]*secret[^"]*"|"[^"]*key[^"]*"' -and $line -notmatch '//') {
                $issues += "File: $($file.Name), Line $lineNumber`: Potential hardcoded sensitive information"
            }
            
            # Check for TODO comments
            if ($line -match 'TODO|FIXME|HACK') {
                $issues += "File: $($file.Name), Line $lineNumber`: TODO/FIXME/HACK comment found"
            }
            
            # Check for empty catch blocks
            if ($line -match 'catch\s*\([^)]*\)\s*\{\s*\}') {
                $issues += "File: $($file.Name), Line $lineNumber`: Empty catch block found"
            }
        }
        
        # Check for missing XML documentation on public methods
        if ($content -match 'public\s+(class|interface|struct|enum)') {
            $publicClasses = [regex]::Matches($content, 'public\s+(class|interface|struct|enum)\s+(\w+)')
            foreach ($match in $publicClasses) {
                $className = $match.Groups[2].Value
                if ($content -notmatch "/// <summary>.*?$className") {
                    $issues += "File: $($file.Name): Public class '$className' missing XML documentation"
                }
            }
        }
    }
    
    # Save issues to file
    $issuesFile = Join-Path $OutputPath "coding-guidelines-issues.txt"
    $issues | Out-File -FilePath $issuesFile -Encoding UTF8
    
    if ($issues.Count -eq 0) {
        Write-Log "✅ No coding guidelines violations found" "SUCCESS"
    } else {
        Write-Log "⚠️  Found $($issues.Count) potential issues. Check $issuesFile for details." "WARNING"
    }
    
    return $issues
}

# Function to generate validation report
function New-ValidationReport {
    param([array]$Issues)
    
    if (-not $GenerateReport) {
        return
    }
    
    Write-Log "📊 Generating validation report..."
    
    $reportPath = Join-Path $OutputPath "validation-report.html"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>C# Code Guidelines Validation Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
        .success { color: #28a745; }
        .warning { color: #ffc107; }
        .error { color: #dc3545; }
        .issues { background-color: #f8f9fa; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .issue-item { margin: 5px 0; padding: 5px; background-color: white; border-left: 3px solid #ffc107; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🔍 C# Code Guidelines Validation Report</h1>
        <p><strong>Generated:</strong> $timestamp</p>
        <p><strong>Project Path:</strong> $ProjectPath</p>
    </div>
    
    <h2>📊 Summary</h2>
    <ul>
        <li><strong>Total Issues Found:</strong> $($Issues.Count)</li>
        <li><strong>StyleCop Analysis:</strong> $($IncludeStyleCop ? 'Enabled' : 'Disabled')</li>
        <li><strong>Security Scan:</strong> $($IncludeSecurityScan ? 'Enabled' : 'Disabled')</li>
    </ul>
    
    <h2>⚠️ Issues Found</h2>
    <div class="issues">
"@

    if ($Issues.Count -eq 0) {
        $html += "<p class='success'>✅ No coding guidelines violations found!</p>"
    } else {
        foreach ($issue in $Issues) {
            $html += "<div class='issue-item'>$issue</div>"
        }
    }
    
    $html += @"
    </div>
    
    <h2>📋 Next Steps</h2>
    <ol>
        <li>Review the issues listed above</li>
        <li>Address StyleCop violations if any</li>
        <li>Fix security issues identified</li>
        <li>Update code to follow Microsoft C# coding guidelines</li>
        <li>Re-run validation to confirm fixes</li>
    </ol>
    
    <h2>📚 Resources</h2>
    <ul>
        <li><a href="https://docs.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/coding-conventions">Microsoft C# Coding Conventions</a></li>
        <li><a href="https://github.com/DotNetAnalyzers/StyleCopAnalyzers">StyleCop Analyzers</a></li>
        <li><a href="https://docs.microsoft.com/en-us/dotnet/fundamentals/code-analysis/overview">.NET Code Analysis</a></li>
    </ul>
</body>
</html>
"@

    $html | Out-File -FilePath $reportPath -Encoding UTF8
    Write-Log "✅ Validation report generated: $reportPath" "SUCCESS"
}

# Main execution
Write-Log "Starting C# code guidelines validation..." "INFO"

# Check prerequisites
if (-not (Test-DotNetInstallation)) {
    exit 1
}

# Build project
if (-not (Build-Project -Path $ProjectPath)) {
    Write-Log "❌ Cannot proceed without successful build" "ERROR"
    exit 1
}

# Run analyses
Invoke-StyleCopAnalysis -Path $ProjectPath
Invoke-SecurityScan -Path $ProjectPath
$issues = Test-CodingGuidelines -Path $ProjectPath

# Generate report
New-ValidationReport -Issues $issues

Write-Log "🎉 Validation completed! Check the $OutputPath directory for detailed results." "SUCCESS"


