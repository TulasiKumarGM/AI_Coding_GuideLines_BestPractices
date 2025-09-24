# GitHub Integration Setup for C# Code Guidelines Validation

This guide will help you set up automated validation of your C# code against Microsoft's coding guidelines using GitHub Actions and various analysis tools.

## 🚀 Quick Start

### 1. Repository Setup

1. **Initialize your repository** (if not already done):
   ```bash
   git init
   git add .
   git commit -m "Initial commit with C# coding guidelines"
   ```

2. **Create a GitHub repository** and push your code:
   ```bash
   git remote add origin https://github.com/yourusername/your-repo-name.git
   git branch -M main
   git push -u origin main
   ```

### 2. GitHub Actions Setup

The repository includes a pre-configured GitHub Actions workflow (`.github/workflows/csharp-code-analysis.yml`) that will:

- ✅ Run on every push and pull request
- ✅ Perform StyleCop analysis
- ✅ Run .NET built-in analyzers
- ✅ Execute security scans
- ✅ Generate code coverage reports
- ✅ Comment on pull requests with analysis results

### 3. Required GitHub Secrets

To enable all features, add these secrets to your GitHub repository:

1. Go to your repository → Settings → Secrets and variables → Actions
2. Add the following secrets:

   | Secret Name | Description | Required |
   |-------------|-------------|----------|
   | `SONAR_TOKEN` | SonarCloud authentication token | Optional (for SonarCloud analysis) |
   | `CODECOV_TOKEN` | Codecov authentication token | Optional (for code coverage reporting) |

### 4. SonarCloud Integration (Optional)

For advanced code quality analysis:

1. **Sign up for SonarCloud**: https://sonarcloud.io/
2. **Create a new project** and connect it to your GitHub repository
3. **Get your SonarCloud token**:
   - Go to Account → Security → Generate Tokens
   - Copy the token and add it as `SONAR_TOKEN` secret
4. **Update the workflow** with your SonarCloud project key:
   ```yaml
   /k:"your-sonarcloud-project-key"
   /o:"your-sonarcloud-organization"
   ```

## 🛠️ Local Development Setup

### Prerequisites

- .NET 8.0 SDK or later
- PowerShell 5.1 or later (Windows) or PowerShell Core (cross-platform)

### Running Local Validation

1. **Navigate to your project directory**:
   ```bash
   cd your-project-directory
   ```

2. **Run the validation script**:
   ```powershell
   # Windows PowerShell
   .\scripts\Validate-CodeGuidelines.ps1 -ProjectPath "." -Verbose

   # PowerShell Core (cross-platform)
   pwsh .\scripts\Validate-CodeGuidelines.ps1 -ProjectPath "." -Verbose
   ```

3. **View results**:
   - Check the `validation-results` directory for detailed reports
   - Open `validation-results/validation-report.html` in your browser

### Script Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `-ProjectPath` | Path to your C# project | "." |
| `-OutputPath` | Directory for validation results | "./validation-results" |
| `-IncludeStyleCop` | Run StyleCop analysis | `$true` |
| `-IncludeSecurityScan` | Run security analysis | `$true` |
| `-GenerateReport` | Generate HTML report | `$true` |
| `-Verbose` | Show detailed output | `$false` |

## 📋 Configuration Files

### 1. StyleCop Configuration (`stylecop.json`)

The repository includes a pre-configured StyleCop settings file that enforces:
- 4-space indentation
- PascalCase for public members
- Required XML documentation
- Consistent spacing rules

### 2. EditorConfig (`.editorconfig`)

EditorConfig ensures consistent code formatting across different IDEs:
- Indentation: 4 spaces
- Line endings: CRLF
- Character encoding: UTF-8
- C# specific formatting rules

### 3. GitHub Actions Workflow

The workflow file (`.github/workflows/csharp-code-analysis.yml`) includes:
- **Code Analysis Job**: StyleCop, .NET analyzers, SonarCloud
- **Security Scan Job**: Security analyzers, dependency checks
- **Documentation Check Job**: XML documentation validation

## 🔧 Customization

### Adding Custom Analyzers

To add additional analyzers to your project:

1. **Add analyzer packages**:
   ```xml
   <PackageReference Include="Microsoft.CodeAnalysis.NetAnalyzers" Version="8.0.0" />
   <PackageReference Include="StyleCop.Analyzers" Version="1.2.0-beta.556" />
   <PackageReference Include="SecurityCodeScan.VS2019" Version="5.6.7" />
   ```

2. **Configure in .csproj**:
   ```xml
   <PropertyGroup>
     <EnableNETAnalyzers>true</EnableNETAnalyzers>
     <RunAnalyzersDuringBuild>true</RunAnalyzersDuringBuild>
     <RunAnalyzersDuringLiveAnalysis>true</RunAnalyzersDuringLiveAnalysis>
   </PropertyGroup>
   ```

### Customizing StyleCop Rules

Edit `stylecop.json` to modify StyleCop behavior:

```json
{
  "settings": {
    "documentationRules": {
      "companyName": "Your Company Name",
      "copyrightText": "Copyright (c) {companyName}. All rights reserved."
    },
    "indentation": {
      "indentationSize": 4,
      "useTabs": false
    }
  }
}
```

### Adding Custom Validation Rules

Extend the PowerShell script (`scripts/Validate-CodeGuidelines.ps1`) to add your own validation rules:

```powershell
# Add custom validation in Test-CodingGuidelines function
if ($line -match 'your-custom-pattern') {
    $issues += "File: $($file.Name), Line $lineNumber`: Your custom violation message"
}
```

## 📊 Understanding Results

### GitHub Actions Results

1. **Check the Actions tab** in your GitHub repository
2. **View workflow runs** and their status
3. **Download artifacts** for detailed analysis results
4. **Review pull request comments** for automated feedback

### Local Validation Results

The validation script generates several output files:

- `validation-results/validation-report.html` - Comprehensive HTML report
- `validation-results/stylecop-results.txt` - StyleCop analysis output
- `validation-results/security-results.txt` - Security scan results
- `validation-results/coding-guidelines-issues.txt` - Custom guideline violations

### Common Issues and Solutions

| Issue | Solution |
|-------|----------|
| Missing XML documentation | Add `/// <summary>` comments to public members |
| StyleCop violations | Follow the formatting rules in `stylecop.json` |
| Security warnings | Review and fix potential security issues |
| Naming convention violations | Follow PascalCase/camelCase conventions |

## 🚀 Advanced Features

### 1. Pre-commit Hooks

Set up pre-commit hooks to validate code before commits:

```bash
# Install pre-commit
pip install pre-commit

# Create .pre-commit-config.yaml
cat > .pre-commit-config.yaml << EOF
repos:
  - repo: local
    hooks:
      - id: csharp-validation
        name: C# Code Guidelines Validation
        entry: pwsh scripts/Validate-CodeGuidelines.ps1
        language: system
        files: \.cs$
EOF

# Install the hook
pre-commit install
```

### 2. IDE Integration

#### Visual Studio
- Install "StyleCop.Analyzers" extension
- Configure to use the included `stylecop.json`
- Enable "Treat warnings as errors" for code analysis

#### Visual Studio Code
- Install "C#" extension
- Install "EditorConfig for VS Code" extension
- The included `.editorconfig` will be automatically applied

### 3. Continuous Integration with Other Platforms

#### Azure DevOps
```yaml
# azure-pipelines.yml
trigger:
- main

pool:
  vmImage: 'ubuntu-latest'

steps:
- task: UseDotNet@2
  inputs:
    packageType: 'sdk'
    version: '8.0.x'

- script: |
    dotnet restore
    dotnet build --configuration Release
    pwsh scripts/Validate-CodeGuidelines.ps1
  displayName: 'Build and Validate'
```

#### GitLab CI
```yaml
# .gitlab-ci.yml
stages:
  - validate

csharp_validation:
  stage: validate
  image: mcr.microsoft.com/dotnet/sdk:8.0
  script:
    - dotnet restore
    - dotnet build --configuration Release
    - pwsh scripts/Validate-CodeGuidelines.ps1
  artifacts:
    reports:
      junit: validation-results/*.xml
```

## 📚 Additional Resources

- [Microsoft C# Coding Conventions](https://docs.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/coding-conventions)
- [StyleCop Analyzers Documentation](https://github.com/DotNetAnalyzers/StyleCopAnalyzers)
- [.NET Code Analysis](https://docs.microsoft.com/en-us/dotnet/fundamentals/code-analysis/overview)
- [EditorConfig](https://editorconfig.org/)
- [SonarCloud](https://sonarcloud.io/)

## 🤝 Contributing

To contribute to this validation setup:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run the validation script to ensure your changes follow the guidelines
5. Submit a pull request

## 📞 Support

If you encounter issues:

1. Check the GitHub Actions logs for detailed error messages
2. Review the validation report for specific violations
3. Consult the Microsoft documentation for coding guidelines
4. Open an issue in the repository with detailed information

---

*This setup ensures your C# code follows Microsoft's best practices and maintains high quality standards across your development team.*


