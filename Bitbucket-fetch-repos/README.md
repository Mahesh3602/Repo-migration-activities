## Setup env variables
$env:BB_URL = "BB_URL"
$env:BB_PAT = "your_secret_token_here"

## Execute scripts
pwsh ./Generate-Inventory.ps1 -BaseUrl $env:BB_URL -Pat $env:BB_PAT -StartRow 2 -EndRow 3

