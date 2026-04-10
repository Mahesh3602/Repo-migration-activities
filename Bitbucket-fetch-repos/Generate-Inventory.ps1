[CmdletBinding()]
param (
    [Parameter(Mandatory=$true)] [int]$StartRow,
    [Parameter(Mandatory=$true)] [int]$EndRow,
    [string]$BaseUrl    = "", 
    [string]$Pat        = "",
    [string]$InputCsv   = "projects.csv",
    [string]$OutputCsv  = "repo_inventory_report.csv"
)

# Headers setup - Ensuring the Token is clean
$headers = @{ 
    Authorization = "Bearer $($Pat.Trim())"
    "Accept"       = "application/json"
}

# Load the CSV
if (-not (Test-Path $InputCsv)) {
    Write-Host "❌ Error: $InputCsv not found." -ForegroundColor Red
    exit
}

$AllProjects = Import-Csv $InputCsv

# Calculate Skip and First logic
# If StartRow is 2, we skip 1 (the header is index 0 in CSV logic, Row 2 is index 0 in object logic)
$SkipCount = $StartRow - 2
if ($SkipCount -lt 0) { $SkipCount = 0 }
$FetchCount = ($EndRow - $StartRow) + 1
$Batch = $AllProjects | Select-Object -Skip $SkipCount -First $FetchCount

Write-Host "`n🚀 Starting Batch: Rows $StartRow to $EndRow" -ForegroundColor Cyan
Write-Host "------------------------------------------------------------"

foreach ($ProjLine in $Batch) {
    # UPDATED: Mapping to your specific CSV headers
    $PKey  = $ProjLine."project-key"
    $PName = $ProjLine."project-name"
    
    if ([string]::IsNullOrWhiteSpace($PKey)) {
        Write-Host "⚠️  Skipping row: project-key is empty." -ForegroundColor Yellow
        continue
    }

    Write-Host "📂 Project: [${PKey}] - ${PName}" -ForegroundColor Yellow

    $repoStart = 0
    $isLastPage = $false

    while (-not $isLastPage) {
        # URL 1: Fetch Repos
        $repoUrl = "${BaseUrl}/rest/api/1.0/projects/${PKey}/repos?start=${repoStart}&limit=100"
        
        try {
            $response = Invoke-RestMethod -Uri $repoUrl -Headers $headers -Method Get -ErrorAction Stop
            
            if ($null -eq $response.values -or $response.values.Count -eq 0) {
                Write-Host "   ℹ️  No repositories found in this project." -ForegroundColor Gray
                break
            }

            foreach ($repo in $response.values) {
                $repoSlug = $repo.slug
                
                # URL 2: Fetch Size (Using the path confirmed in your reference)
                $sizeMB = "0.00"
                $sizeUrl = "${BaseUrl}/projects/${PKey}/repos/${repoSlug}/sizes"
                
                try {
                    $sizeRes = Invoke-RestMethod -Uri $sizeUrl -Headers $headers -Method Get -ErrorAction SilentlyContinue
                    if ($sizeRes.repository) {
                        $sizeMB = [math]::Round($sizeRes.repository / 1MB, 2)
                    }
                } catch { 
                    # Size API often requires higher permissions, default to 0.00 if it fails
                }

                # Extract HTTP Clone URL safely
                $httpUrl = ($repo.links.clone | Where-Object { $_.name -eq 'http' }).href

                # Construct result object
                [PSCustomObject]@{
                    "Project"      = $PName
                    "ProjectKey"   = $PKey
                    "Repository"   = $repo.name
                    "RepoUrl"      = $httpUrl
                    "RepoSizeMB"   = $sizeMB
                    "IsDisabled"   = if ($repo.archived) { "True" } else { "False" }
                } | Export-Csv -Path $OutputCsv -Append -NoTypeInformation -Encoding UTF8
                
                Write-Host "   ✅ Logged: ${repoSlug}" -ForegroundColor Gray
            }

            $isLastPage = $response.isLastPage
            if (-not $isLastPage) { $repoStart = $response.nextPageStart }
        }
        catch {
            if ($_.Exception.Response.StatusCode -eq 401) {
                Write-Host "   ❌ 401 Unauthorized: Your token is invalid or expired." -ForegroundColor Red
            } else {
                Write-Host "   ❌ Error fetching repos for ${PKey}: $($_.Exception.Message)" -ForegroundColor Red
            }
            break # Move to next project
        }
    }
}

Write-Host "`n✅ Process Complete. Results in: $OutputCsv" -ForegroundColor Green