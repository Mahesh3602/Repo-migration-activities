# GitHub Mannequin Management Tool

This directory contains a unified PowerShell script (`Manage-Mannequins.ps1`) designed to simplify the generation and reclamation of "mannequins" (unmapped user identities) when migrating from Azure DevOps to GitHub using the GitHub CLI (`gh`).

---

## 📋 Prerequisites

Before running the script, ensure your local environment meets the following requirements:

1. **PowerShell 7+ (Core)** or Windows PowerShell.
2. **GitHub CLI (`gh`)** installed on your system ([Download here](https://cli.github.com/)).
3. **Personal Access Token (PAT)**: A GitHub Personal Access Token (Classic) with the following scopes:
   * `repo` (Full control of repositories)
   * `admin:org` (Full control of organization settings, required for user mapping)

---

## 🛠️ Script Parameter Reference

The script accepts the following parameters:

| Parameter | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `-Action` | String | **Yes** | Accepts either `Generate` or `Reclaim`. |
| `-GitHubOrg` | String | **Yes** | The exact name of your target GitHub Organization. |
| `-Pat` | String | **Yes** | Your GitHub Personal Access Token (Classic). |
| `-CsvPath` | String | No | Custom path for the CSV. Defaults to `mannequins_<OrgName>.csv`. |

---

## 🚀 Step-by-Step Execution Guide

### Step 1: Set up your GH Token & ORG
For security, it is highly recommended to store your token in an environment variable rather than hardcoding it into your commands.

```powershell
$env:GH_PAT = "ghp_yourActualGitHubPersonalAccessToken123456"
$env:GH_ORG = "your_GH_ORG"
```

### Step 2: Generate the Mannequin CSV Mapping File
Run the script with the Generate action. This will scan your specified GitHub Organization for unmapped mannequin users and export them to a dynamic CSV file.

```powershell
pwsh ./Manage-Mannequins.ps1 -Action Generate -GitHubOrg $env:GH_ORG -Pat $env:GH_PAT
```
Output: This creates a file named mannequins_Demo-org-cust1.csv in your current working directory.


### Step 3: Populate the CSV File
* Open the newly generated mannequins_Demo-org-cust1.csv file in Microsoft Excel or any text/CSV editor.
* Locate the target user column (usually labeled GitHub User or target-user).
* Manually map each Azure DevOps identity by typing the exact target GitHub handle of the user who should inherit that history.
* Save and close the file.
