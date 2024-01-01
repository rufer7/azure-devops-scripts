<#
.SYNOPSIS
  Returns all service connections / service endpoints of an Azure DevOps organization
.DESCRIPTION
  An Azure DevOps automation script that returns all service connections / service endpoints of an Azure DevOps organization
.PARAMETER PersonalAccessToken
  Azure DevOps access token with the following scopes: User Profile (Read), Project and Team (Read), Service Connections (Read & query)
.PARAMETER OrganizationName
  Name of the Azure DevOps organization
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
  <Example goes here. Repeat this attribute for more than one example>
#>
PARAM
(
	[Parameter(Mandatory = $true, Position = 0, HelpMessage="Azure DevOps access token with scopes: User Profile (Read), Project and Team (Read), Service Connections (Read & query).")]
 	[string] $PersonalAccessToken
	,
	[Parameter(Mandatory = $true, Position = 1)]
	[string] $OrganizationName
)

$base64encodedPAT = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("`:$PersonalAccessToken"))

$uri = "https://dev.azure.com/{0}/_apis/projects?api-version=7.2-preview.4" -f $OrganizationName
$response = Invoke-RestMethod -Method Get -Uri $uri -Headers @{'Authorization' = "Basic $base64encodedPAT" }

$projects = $response.value

$serviceConnections = @{}

foreach ($project in $projects) {
	$uri = "https://dev.azure.com/{0}/{1}/_apis/serviceendpoint/endpoints?api-version=7.2-preview.4" -f $Organizationname, $project.name
	$response = Invoke-RestMethod -Method Get -Uri $uri -Headers @{'Authorization' = "Basic $base64encodedPAT" }

	$serviceEndpoints = $resonse.value
	foreach ($serviceEndpoint in $serviceEndpoints) {
 		$serviceConnections.Add($serviceEndpoint)
	}
}

# TODO - show name type authorization.scheme data.environment data.scopeLevel data.subscriptionId data.subscriptionName 
