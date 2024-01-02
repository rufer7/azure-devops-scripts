<#
.SYNOPSIS
  Returns all service connections / service endpoints of an Azure DevOps organization
.DESCRIPTION
  An Azure DevOps automation script that returns all service connections / service endpoints of an Azure DevOps organization
.PARAMETER PersonalAccessToken
  Azure DevOps personal access token (PAT) with the following scopes: User Profile (Read), Project and Team (Read), Service Connections (Read & query)
.PARAMETER OrganizationName
  Name of the Azure DevOps organization
.PARAMETER PrintToConsole
  If set to true, the output will be printed to the console
.INPUTS
  None
.OUTPUTS
  The service connections / service endpoints of the given Azure DevOps organization
.NOTES
  Version:        1.0
  Author:         Marc Rufer
  Creation Date:  01.01.2024
  Purpose/Change: Initial script development
.EXAMPLE
  Retrieve service connections without printing to console
  .\Get-ServiceConnections.ps1 -PersonalAccessToken "your_personal_access_token" -OrganizationName "your_organization_name"
.EXAMPLE
  Retrieve service connections and print to console
  .\Get-ServiceConnections.ps1 -PersonalAccessToken "your_personal_access_token" -OrganizationName "your_organization_name" -PrintToConsole
#>
PARAM
(
	[Parameter(Mandatory = $true, Position = 0, HelpMessage="Azure DevOps personal access token (PAT) with scopes: User Profile (Read), Project and Team (Read), Service Connections (Read & query).")]
 	[string] $PersonalAccessToken
	,
	[Parameter(Mandatory = $true, Position = 1)]
	[string] $OrganizationName
  ,
  [Parameter(Mandatory = $false, Position = 2)]
  [switch] $PrintToConsole = $false
)

$base64encodedPAT = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("`:$PersonalAccessToken"))

$uri = "https://dev.azure.com/{0}/_apis/projects?api-version=7.2-preview.4" -f $OrganizationName
$response = Invoke-RestMethod -Method Get -Uri $uri -Headers @{'Authorization' = "Basic $base64encodedPAT" }
$projects = $response.value

$serviceConnections = [System.Collections.ArrayList]::new()

foreach ($project in $projects) {
	$uri = "https://dev.azure.com/{0}/{1}/_apis/serviceendpoint/endpoints?api-version=7.2-preview.4" -f $Organizationname, $project.name
	$response = Invoke-RestMethod -Method Get -Uri $uri -Headers @{'Authorization' = "Basic $base64encodedPAT" }

	$serviceEndpoints = $response.value
	foreach ($serviceEndpoint in $serviceEndpoints) {
 		$null = $serviceConnections.Add($serviceEndpoint)
	}
}

if ($PrintToConsole) {
  Write-Host "Azure DevOps organization: $OrganizationName" -ForegroundColor Green
  Write-Host ("Projects count:            {0}" -f $projects.Count) -ForegroundColor Green
  Write-Host ("Service connection count:  {0}" -f $serviceConnections.Count) -ForegroundColor Green
  Write-Host ""

  $serviceConnections | Format-Table -AutoSize -Wrap -GroupBy isOutdated -Property name, type, @{Name="environment"; Expression={$_.data.environment}}, @{Name="scopeLevel"; Expression={$_.data.scopeLevel}}, @{Name="subscriptionName"; Expression={$_.data.subscriptionName}}, @{Name="authScheme"; Expression={$_.authorization.scheme}}, isShared, isReady
}

return $serviceConnections
