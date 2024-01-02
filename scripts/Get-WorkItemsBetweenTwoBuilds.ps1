<#
.SYNOPSIS
  Returns all linked work items between two builds
.DESCRIPTION
  An Azure DevOps automation script that returns all linked work items between two builds
.PARAMETER PersonalAccessToken
  Azure DevOps personal access token (PAT) with the following scopes: Build (Read), Work Items (Read)
.PARAMETER OrganizationName
  Name of the Azure DevOps organization
.PARAMETER ProjectName
  Name of the Azure DevOps project
.PARAMETER FromBuildId
  Id of the build to start searching
.PARAMETER ToBuildId
  Id of the build to stop searching
.INPUTS
  None  
.OUTPUTS
  The linked work items between the two builds - printed to the console
.NOTES
  Version:        1.0
  Author:         Marc Rufer
  Creation Date:  21.11.2023
  Purpose/Change: Initial script development
  
.EXAMPLE
  <Example goes here. Repeat this attribute for more than one example>
#>
PARAM
(
	[Parameter(Mandatory = $true, Position = 0, HelpMessage="Azure DevOps personal access token (PAT) with scopes: Build (Read), Work Items (Read).")]
 	[string] $PersonalAccessToken
	,
	[Parameter(Mandatory = $true, Position = 1)]
	[string] $OrganizationName
 	,
	[Parameter(Mandatory = $true, Position = 2)]
	[string] $ProjectName
	,
	[Parameter(Mandatory = $true, Position = 3)]
	[string] $FromBuildId
	,
	[Parameter(Mandatory = $true, Position = 4)]
	[string] $ToBuildId
)

$base64encodedPAT = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("`:$PersonalAccessToken"))

$uri = "https://dev.azure.com/{0}/{1}/_apis/build/workitems?fromBuildId={2}&toBuildId={3}&api-version=7.0" -f $OrganizationName, $ProjectName, $FromBuildId, $ToBuildId
$response = Invoke-RestMethod -Method Get -Uri $uri -Headers @{'Authorization' = "Basic $base64encodedPAT" }
 
ForEach ($wi in $response.value) {
    $uri = "https://dev.azure.com/{0}/{1}/_apis/wit/workItems/{2}?api-version=7.1-preview.3" -f $OrganizationName, $ProjectName, $wi.id
    $workItem = Invoke-RestMethod -Method Get -Uri $uri -Headers @{'Authorization' = "Basic $base64encodedPAT" }

    Write-Host "--------------------"
    Write-Host $workItem.fields.'System.WorkItemType'
    Write-Host $workItem.fields.'System.Title'
    Write-Host $workItem.url
    Write-Host $workItem.id
    Write-Host ""
}
