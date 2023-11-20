PARAM
(
 [Parameter(Mandatory = $true, Position = 0, HelpMessage="Azure DevOps access token with scopes: Build (Read), Work Items (Read).")]
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
 
$response = Invoke-RestMethod -Method Get -Uri "https://dev.azure.com/{$OrganizationName}/{$ProjectName}/_apis/build/workitems?fromBuildId={$FromBuildId}&toBuildId={$ToBuildId}&api-version=7.0" -Headers @{'Authorization' = "Basic $base64encodedPAT" }
 
ForEach ($wi in $response.value) {
    $uri = "https://dev.azure.com/{$organization}/{$project}/_apis/wit/workItems/{0}?api-version=7.1-preview.3" -f $wi.id
    $workItem = Invoke-RestMethod -Method Get -Uri $uri -Headers @{'Authorization' = "Basic $base64encodedPAT" }
 
    Write-Host $workItem.fields.'System.WorkItemType'
    Write-Host $workItem.fields.'System.Title'
    Write-Host $workItem.url
    Write-Host $workItem.id
    Write-Host ""
}
