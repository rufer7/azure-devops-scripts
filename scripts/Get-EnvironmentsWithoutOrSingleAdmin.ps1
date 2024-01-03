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

	$envs = $response.value
	foreach ($env in $envs) {
    $uri = "https://dev.azure.com/{0}/_apis/securityroles/scopes/distributedtask.environmentreferencerole/roleassignments/resources/{1}_{2}?api-version=7.1-preview.1" -f $Organizationname, $project.id, $env.id
    $response = Invoke-RestMethod -Method Get -Uri $uri -Headers @{'Authorization' = "Basic $base64encodedPAT" }

    $assignmentsToAdministratorRole = $response.value | ? { $_.role.identifier -eq "distributedtask.environmentreferencerole.Administrator" }

    # add to result list, if no administrator role assignment exists
    if ($assignmentsToAdministratorRole.Count -eq 0) {
      $null = $environments.Add($env)
    # add to result list, if only a single user is assigned to the administrator role
    } elseif ($assignmentsToAdministratorRole -ne $null -and $assignmentsToAdministratorRole.Count -eq $null -and $assignmentsToAdministratorRole.identity.displayName -notcontains "\") {
      $null = $environments.Add($env)
    } else {
      Write-Host "Environment '$($env.name)' ($($env.id)) has more than one user assigned to the administrator role" -ForegroundColor Yellow
    }
	}
}

if ($PrintToConsole) {
  Write-Host "Azure DevOps organization:                        $OrganizationName" -ForegroundColor Green
  Write-Host ("Projects count:                                   {0}" -f $projects.Count) -ForegroundColor Green
  Write-Host ("Environments without or with single admin:        {0}" -f $envs.Count) -ForegroundColor Green
  Write-Host ""

  $environments | Format-Table -AutoSize -Wrap -Property id, name, @{Name="projectId"; Expression={$_.project.id}}, @{Name="projectName"; Expression={($projects |? id -eq $_.project.id).name}}
}

return $environments
