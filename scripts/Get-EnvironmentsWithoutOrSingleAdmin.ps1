<#
.SYNOPSIS
  Returns all hard-to-manage environments of an Azure DevOps organization
.DESCRIPTION
  An Azure DevOps automation script that returns all environments of an Azure DevOps organization without an administrator or with only a single user in administrator role
.PARAMETER PersonalAccessToken
  Azure DevOps personal access token (PAT) with the following scopes: User Profile (Read), Project and Team (Read), Build (Read), Environment (Read & manage)
.PARAMETER OrganizationName
  Name of the Azure DevOps organization
.PARAMETER PrintToConsole
  If set to true, the output will be printed to the console
.INPUTS
  None
.OUTPUTS
  The environments of the given Azure DevOps organization without an administrator or with only a single user in administrator role
.NOTES
  Version:        1.0
  Author:         Marc Rufer
  Creation Date:  02.01.2024
  Purpose/Change: Initial script development
#>
PARAM
(
	[Parameter(Mandatory = $true, Position = 0, HelpMessage="Azure DevOps personal access token (PAT) with scopes: User Profile (Read), Project and Team (Read), Build (Read), Environment (Read & manage).")]
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

$environments = [System.Collections.ArrayList]::new()

foreach ($project in $projects) {
	$uri = "https://dev.azure.com/{0}/{1}/_apis/pipelines/environments?api-version=7.2-preview.1" -f $Organizationname, $project.name
	$response = Invoke-RestMethod -Method Get -Uri $uri -Headers @{'Authorization' = "Basic $base64encodedPAT" }

	$result = $response.value
	foreach ($item in $result) {
 		$null = $environments.Add($item)
	}
}

if ($PrintToConsole) {
  Write-Host "Azure DevOps organization: $OrganizationName" -ForegroundColor Green
  Write-Host ("Projects count:            {0}" -f $projects.Count) -ForegroundColor Green
  Write-Host ("Environments count      :  {0}" -f $environments.Count) -ForegroundColor Green
  Write-Host ""

  $environments | Format-Table -AutoSize -Wrap -GroupBy isOutdated -Property name, type, @{Name="environment"; Expression={$_.data.environment}}, @{Name="scopeLevel"; Expression={$_.data.scopeLevel}}, @{Name="subscriptionName"; Expression={$_.data.subscriptionName}}, @{Name="authScheme"; Expression={$_.authorization.scheme}}, isShared, isReady
}

return $environments
