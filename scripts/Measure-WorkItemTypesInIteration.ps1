<#
.SYNOPSIS
Measures the percentage of work item types and the bug to rest of types ratio within an iteration

.DESCRIPTION
A PowerShell script that utilizes the Azure DevOps Services REST API to fetch work items within a specified iteration and calculates the percentage of each work item type and the ratio of bugs to the rest of the work item types

.PARAMETER PersonalAccessToken
Azure DevOps personal access token (PAT) with the following scopes: Work Items (Read)

.PARAMETER OrganizationName
Name of the Azure DevOps organization

.PARAMETER ProjectName
Name of the Azure DevOps project

.PARAMETER TeamName
Name of the Azure DevOps team

.PARAMETER IterationPath
The iteration path to measure work item types in

.PARAMETER WorkItemTypes
The work item types to be considered

.INPUTS
None

.OUTPUTS
The calculated percentages and ratios - printed to the console

.NOTES
Version:        1.0
Author:         Marc Rufer & GitHub Copilot Workspace
Creation Date:  14.05.2024
Purpose/Change: Initial script development

.EXAMPLE
PS> .\Measure-WorkItemTypesInIteration.ps1 -PersonalAccessToken "PAT_HERE" -OrganizationName "ORG_NAME_HERE" -ProjectName "PROJECT_NAME_HERE" -TeamName "TEAM_NAME_HERE" -IterationPath "ITERATION_PATH_HERE"

.EXAMPLE
PS> .\Measure-WorkItemTypesInIteration.ps1 -PersonalAccessToken "PAT_HERE" -OrganizationName "ORG_NAME_HERE" -ProjectName "PROJECT_NAME_HERE" -TeamName "TEAM_NAME_HERE" -IterationPath "ITERATION_PATH_HERE" -WorkItemTypes "User Story" "Epic" "Bug"
#>
PARAM
(
    [Parameter(Mandatory = $true, Position = 0, HelpMessage="Azure DevOps personal access token (PAT) with scopes: Work Items (Read).")]
    [string] $PersonalAccessToken
    ,
    [Parameter(Mandatory = $true, Position = 1)]
    [string] $OrganizationName
    ,
    [Parameter(Mandatory = $true, Position = 2)]
    [string] $ProjectName
    ,
    [Parameter(Mandatory = $true, Position = 3)]
    [string] $TeamName
    ,
    [Parameter(Mandatory = $true, Position = 4)]
    [string] $IterationPath
    ,
    [Parameter(Mandatory = $false)]
    [string[]] $WorkItemTypes = "Bug", "User Story"
)

function Get-WorkItemsInIteration {
    param (
        [string] $personalAccessToken,
        [string] $organizationName,
        [string] $projectName,
        [string] $teamName,
        [string] $iterationPath,
        [string[]] $workItemTypes
    )

    $base64AuthInfo = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("`:$personalAccessToken"))
    $workItemsUri = "https://dev.azure.com/$organizationName/$projectName/$teamName/_apis/wit/wiql?api-version=6.0"
    $body = @{
        query = "SELECT [System.Id] FROM WorkItems WHERE [System.IterationPath] = '$iterationPath' AND [System.WorkItemType] IN ('$($workItemTypes -join "','")')"
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod -Uri $workItemsUri -Method Post -Body $body -ContentType "application/json" -Headers @{Authorization=("Basic $base64AuthInfo")}
        return $response.workItems.id
    }
    catch {
        Write-Error "Failed to fetch work items: $_"
        exit 1
    }
}

function Calculate-WorkItemTypesPercentage {
    param (
        [string] $personalAccessToken,
        [string] $organizationName,
        [string[]] $workItemIds
    )

    $base64AuthInfo = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("`:$personalAccessToken"))
    $workItemTypes = @{}
    $totalWorkItems = $workItemIds.Count

    $workItemsCountPerType = @{}

    foreach ($id in $workItemIds) {
        $workItemUri = "https://dev.azure.com/$organizationName/_apis/wit/workitems/$($id)?api-version=6.0"
        try {
            $workItem = Invoke-RestMethod -Uri $workItemUri -Method Get -Headers @{Authorization=("Basic $base64AuthInfo")}
            $type = $workItem.fields.'System.WorkItemType'
            $workItemsCountPerType[$type] = $workItemsCountPerType[$type] + 1
        }
        catch {
            Write-Error "Failed to fetch work item details: $_"
            continue
        }
    }

     foreach ($type in $workItemsCountPerType.Keys) {
        $percentage = ($workItemsCountPerType[$type] / $totalWorkItems) * 100
        Write-Host "$($type): $($percentage)%"
    }
    
    if ($workItemsCountPerType['Bug']) {
        $bugRatio = ($workItemsCountPerType['Bug'] / ($totalWorkItems - $workItemsCountPerType['Bug'])) * 100
        Write-Host "Bug to rest of types ratio: $($bugRatio)%"
    }
    else {
        Write-Host "No bugs found in the iteration."
    }
}

Write-Host "Azure DevOps organization: $OrganizationName" -ForegroundColor Green
Write-Host "Azure DevOps project name: $ProjectName" -ForegroundColor Green
Write-Host "Azure DevOps team name:    $TeamName" -ForegroundColor Green
Write-Host "Iteration path:            $IterationPath" -ForegroundColor Green

$workItemIds = Get-WorkItemsInIteration -personalAccessToken $PersonalAccessToken -organizationName $OrganizationName -projectName $ProjectName -teamName $TeamName -iterationPath $IterationPath -workItemTypes $WorkItemTypes
Calculate-WorkItemTypesPercentage -personalAccessToken $PersonalAccessToken -organizationName $OrganizationName -workItemIds $workItemIds
