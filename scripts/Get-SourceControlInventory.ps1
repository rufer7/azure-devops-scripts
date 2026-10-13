<#
.SYNOPSIS
Exports an inventory of Azure DevOps Git repositories and top-level TFVC paths, including their latest change details, to a CSV file.

.DESCRIPTION
An Azure DevOps automation script that returns an inventory of Git repositories and top-level TFVC paths, including their latest change details.

.PARAMETER CollectionUrl
URL of the Azure DevOps collection to query.

.PARAMETER OutputCsv
Path to the output CSV file where the inventory will be saved.

.PARAMETER PersonalAccessToken
Azure DevOps personal access token (PAT) with the following scopes: Code (Read)

.PARAMETER UseDefaultCredentials
If set, the script will use the default credentials instead of a personal access token (PAT)

.INPUTS
None

.OUTPUTS
An inventory of Azure DevOps Git repositories and top-level TFVC paths, including their latest change details

.NOTES
Version:        1.0
Authors:        Marc Rufer, GitHub Copilot
Creation Date:  13.10.2026
Purpose/Change: Initial script development

.EXAMPLE
PS> .\Get-SourceControlInventory.ps1 -CollectionUrl "http://your-azure-devops-server:8080/tfs/DefaultCollection" -OutputCsv "arbitrary-sourcecontrol-inventory.csv" -PersonalAccessToken "PAT_HERE"

.EXAMPLE
PS> .\Get-SourceControlInventory.ps1 -CollectionUrl "http://your-azure-devops-server:8080/tfs/DefaultCollection" -OutputCsv "arbitrary-sourcecontrol-inventory.csv" -UseDefaultCredentials
#>
param
(
    [Parameter(Mandatory = $true, Position = 0, HelpMessage="URL of the Azure DevOps collection to query.")]
    [string] $CollectionUrl
    ,
    [Parameter(Mandatory = $true, Position = 1, HelpMessage="Path to the output CSV file where the inventory will be saved.")]
    [string] $OutputCsv
    ,
    [Parameter(Mandatory = $false, Position = 2, HelpMessage="Azure DevOps personal access token (PAT) with the following scopes: Code (Read)")]
    [string] $PersonalAccessToken
    ,
    [Parameter(Mandatory = $false, Position = 3, HelpMessage="If set, the script will use the default credentials instead of a personal access token (PAT)")]
    [switch] $UseDefaultCredentials
)

if (-not $UseDefaultCredentials -and [string]::IsNullOrWhiteSpace($PersonalAccessToken)) {
    throw "Provide -PersonalAccessToken or use -UseDefaultCredentials"
}

if (-not $UseDefaultCredentials) {
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$Pat"))
    $headers = @{
        Authorization = "Basic $base64AuthInfo"
    }
}

function Invoke-AdoGet {
    param([string] $Url)

    if ($UseDefaultCredentials) {
        Invoke-RestMethod -Uri $Url -Method Get -UseDefaultCredentials -ContentType "application/json"
    }
    else {
        Invoke-RestMethod -Uri $Url -Method Get -Headers $headers -ContentType "application/json"
    }
}

$results = @()

# 1. Projects
$projectsUrl = "$CollectionUrl/_apis/projects?api-version=7.0"
$projects = (Invoke-AdoGet -Url $projectsUrl).value

foreach ($project in $projects) {
    Write-Host "Processing project: $($project.name)"

    # 2. Git repositories
    $gitReposUrl = "$CollectionUrl/$($project.name)/_apis/git/repositories?api-version=7.0"

    try {
        $gitRepos = (Invoke-AdoGet -Url $gitReposUrl).value
    }
    catch {
        Write-Warning "Could not get Git repos for project $($project.name): $($_.Exception.Message)"
        $gitRepos = @()
    }

    foreach ($repo in $gitRepos) {
        Write-Host "  Git repo: $($repo.name)"

        $commitsUrl = "$CollectionUrl/$($project.name)/_apis/git/repositories/$($repo.id)/commits?`$top=1&api-version=7.0"

        try {
            $commitResponse = Invoke-AdoGet -Url $commitsUrl
            $lastCommit = $commitResponse.value | Select-Object -First 1

            if ($lastCommit) {
                $results += [PSCustomObject]@{
                    Project        = $project.name
                    SourceType     = "Git"
                    NameOrPath     = $repo.name
                    LastAuthor     = $lastCommit.committer.name
                    LastAuthorMail = $lastCommit.committer.email
                    LastChangeDate = $lastCommit.committer.date
                    ChangeId       = $lastCommit.commitId
                    Comment        = $lastCommit.comment
                }
            }
            else {
                $results += [PSCustomObject]@{
                    Project        = $project.name
                    SourceType     = "Git"
                    NameOrPath     = $repo.name
                    LastAuthor     = ""
                    LastAuthorMail = ""
                    LastChangeDate = ""
                    ChangeId       = ""
                    Comment        = "No commits"
                }
            }
        }
        catch {
            $results += [PSCustomObject]@{
                Project        = $project.name
                SourceType     = "Git"
                NameOrPath     = $repo.name
                LastAuthor     = ""
                LastAuthorMail = ""
                LastChangeDate = ""
                ChangeId       = ""
                Comment        = "Error reading commits: $($_.Exception.Message)"
            }
        }
    }

    # 3. TFVC roots / latest changesets
    # Get items under $/ProjectName recursively; adjust if your TFVC layout differs
    $tfvcUrl = "$CollectionUrl/$($project.name)/_apis/tfvc/items?scopePath=`$/$($project.name)&recursionLevel=OneLevel&includeLinks=false&api-version=7.0"

    try {
        $tfvcItems = (Invoke-AdoGet -Url $tfvcUrl).value
    }
    catch {
        Write-Warning "Could not get TFVC items for project $($project.name): $($_.Exception.Message)"
        $tfvcItems = @()
    }

    if ($tfvcItems.Count -gt 0) {
        foreach ($item in $tfvcItems) {
            if ($item.isFolder -eq $true -or $item.path -eq "`$/$($project.name)") {
                $encodedPath = [System.Uri]::EscapeDataString($item.path)
                $changesetsUrl = "$CollectionUrl/$($project.name)/_apis/tfvc/changesets?searchCriteria.itemPath=$encodedPath&`$top=1&api-version=7.0"

                try {
                    $changesetResponse = Invoke-AdoGet -Url $changesetsUrl
                    $lastChangeset = $changesetResponse.value | Select-Object -First 1

                    if ($lastChangeset) {
                        $results += [PSCustomObject]@{
                            Project        = $project.name
                            SourceType     = "TFVC"
                            NameOrPath     = $item.path
                            LastAuthor     = $lastChangeset.author.displayName
                            LastAuthorMail = ""
                            LastChangeDate = $lastChangeset.createdDate
                            ChangeId       = $lastChangeset.changesetId
                            Comment        = $lastChangeset.comment
                        }
                    }
                }
                catch {
                    $results += [PSCustomObject]@{
                        Project        = $project.name
                        SourceType     = "TFVC"
                        NameOrPath     = $item.path
                        LastAuthor     = ""
                        LastAuthorMail = ""
                        LastChangeDate = ""
                        ChangeId       = ""
                        Comment        = "Error reading TFVC changesets: $($_.Exception.Message)"
                    }
                }
            }
        }
    }
}

$results | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8

Write-Host "Done. Output written to $OutputCsv"

return $results
