<#
.SYNOPSIS
  Returns all service connections / service endpoints of an Azure DevOps organization
.DESCRIPTION
  An Azure DevOps automation script that returns all service connections / service endpoints of an Azure DevOps organization
.PARAMETER PersonalAccessToken
  Azure DevOps access token with the following scopes: Service Connections (Read & query)
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
	[Parameter(Mandatory = $true, Position = 0, HelpMessage="Azure DevOps access token with scopes: Service Connections (Read & query).")]
 	[string] $PersonalAccessToken
	,
	[Parameter(Mandatory = $true, Position = 1)]
	[string] $OrganizationName
)

$base64encodedPAT = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("`:$PersonalAccessToken"))

# TODO - list projects
# TODO - for each project -> Get Service Endpoints

# TODO - show name type authorization.scheme data.environment data.scopeLevel data.subscriptionId data.subscriptionName 
