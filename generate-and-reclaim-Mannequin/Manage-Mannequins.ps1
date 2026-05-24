<#
.SYNOPSIS
    Manages GitHub Enterprise Importer mannequin generation and reclamation.
.EXAMPLE
    # Step 1: Generate the CSV mapping file
    .\Manage-Mannequins.ps1 -Action Generate -GitHubOrg "$env:GH-ORG" -Pat $env:GH_PAT

    # Step 2: (After editing the CSV) Reclaim the identities
    .\Manage-Mannequins.ps1 -Action Reclaim -GitHubOrg "$env:GH-ORG" -Pat $env:GH_PAT
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [ValidateSet('Generate', 'Reclaim')]
    [string]$Action,

    [Parameter(Mandatory = $true)]
    [string]$GitHubOrg,

    [Parameter(Mandatory = $true)]
    [string]$Pat,

    [Parameter(Mandatory = $false)]
    [string]$CsvPath = "mannequins_${GitHubOrg}.csv"
)

# 1. Set the environment variable securely for this process scope only
$env:GH_PAT = $Pat

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "Action: $Action"
Write-Host "Target GitHub Org: $GitHubOrg"
Write-Host "CSV File: $CsvPath"
Write-Host "=============================================" -ForegroundColor Cyan

# 2. Prerequisites Validation
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Error "GitHub CLI (gh) is not installed. Please install it and try again."
    exit 1
}

# Verify or install the extension
$extensions = gh extension list
if ($extensions -notmatch "ado2gh") {
    Write-Host "⚠️ 'ado2gh' extension not detected. Attempting to install..." -ForegroundColor Yellow
    gh extension install github/gh-ado2gh
}

# 3. Execution Logic
switch ($Action) {
    'Generate' {
        Write-Host "🚀 Running gh ado2gh generate-mannequin-csv..." -ForegroundColor Green
        
        # Run the generation command
        gh ado2gh generate-mannequin-csv --github-org $GitHubOrg --output $CsvPath

        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n✅ Success! Mapping file saved to: $CsvPath" -ForegroundColor Green
            Write-Host "👉 Open this CSV and fill in the 'target-user' column with real GitHub handles before reclaiming." -ForegroundColor Yellow
        } else {
            Write-Error "Failed to generate mannequin CSV."
        }
    }

    'Reclaim' {
        if (-not (Test-Path $CsvPath)) {
            Write-Error "Target CSV file path '$CsvPath' does not exist. Did you run the 'Generate' step first?"
            exit 1
        }

        Write-Host "🚀 Running gh ado2gh reclaim-mannequin..." -ForegroundColor Green
        
        # Run the reclamation command
        gh ado2gh reclaim-mannequin --github-org $GitHubOrg --csv $CsvPath

        if ($LASTEXITCODE -eq 0) {
            Write-Host "`n✅ Reclamation process completed successfully!" -ForegroundColor Green
        } else {
            Write-Error "Reclamation failed. Check the error logs above."
        }
    }
}
