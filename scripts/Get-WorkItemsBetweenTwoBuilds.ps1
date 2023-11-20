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

$uri = "https://dev.azure.com/{0}/{1}/_apis/build/workitems?fromBuildId={2}&toBuildId={3}&api-version=7.0" -f $OrganizationName, $ProjectName, $FromBuildId, $ToBuildId
$response = Invoke-RestMethod -Method Get -Uri $uri -Headers @{'Authorization' = "Basic $base64encodedPAT" }
 
ForEach ($wi in $response.value) {
    $uri = "https://dev.azure.com/{0}/{1}/_apis/wit/workItems/{2}?api-version=7.1-preview.3" -f $OrganizationName, $ProjectName, $wi.id
    $workItem = Invoke-RestMethod -Method Get -Uri $uri -Headers @{'Authorization' = "Basic $base64encodedPAT" }
 
    Write-Host $workItem.fields.'System.WorkItemType'
    Write-Host $workItem.fields.'System.Title'
    Write-Host $workItem.url
    Write-Host $workItem.id
    Write-Host ""
}
