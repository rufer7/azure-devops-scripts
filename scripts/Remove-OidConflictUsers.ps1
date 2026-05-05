#Requires -Version 7.0
<#
.SYNOPSIS
  Deletes Azure DevOps users whose principalName contains OIDCONFLICT_UpnReuse_
.DESCRIPTION
  An automation script that queries all Azure DevOps users of the given organization whose principalName contains OIDCONFLICT_UpnReuse_ and deletes them.
  IMPORTANT: The script requires the Azure CLI to be installed on the executing machine
  IMPORTANT: The executing user needs to be a member of the "Project Collection Administrators" group
  For more information see https://learn.microsoft.com/en-sg/answers/questions/5569893/azure-devops-oid-conflict
.PARAMETER OrganizationName
  Name of the Azure DevOps organization
.PARAMETER DryRun
  Force a dry/test run – no data will be deleted; the affected users will be written to the console
.INPUTS
  None
.OUTPUTS
  List of users to be deleted
.NOTES
  Version:              1.0
  Author:               rufer7
  Creation Date:        05.05.2026
  Last Modified Date:   05.05.2026
  Changelog:
    - Initial script development
#>
PARAM
(
  [Parameter(Mandatory = $true, Position = 0, HelpMessage = "Name of the Azure DevOps organization")]
  [string] $OrganizationName
  ,
  [Parameter(Mandatory = $false, Position = 1, HelpMessage = "Force a dry/test run – no data will be deleted; the affected users will be written to the console")]
  [switch] $DryRun = $false
)

$null = az account show --output none 2>$null
if ($LASTEXITCODE -ne 0) {
  throw "Azure CLI is not authenticated. Run 'az login' before executing this script, or use a non-interactive Azure CLI login method in your automation environment."
}

$accessToken = (az account get-access-token --query accessToken --output tsv)
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($accessToken)) {
  throw "Failed to acquire an Azure access token from the current Azure CLI session."
}

Write-Host "Azure DevOps organization: $OrganizationName" -ForegroundColor Yellow

$requestBody = @{query = "OIDCONFLICT_UpnReuse_"; subjectKind = @("User")} | ConvertTo-Json
$response = Invoke-WebRequest -Method POST -Uri https://vssps.dev.azure.com/$OrganizationName/_apis/graph/subjectquery?api-version=7.1-preview.1 -Body $requestBody -Headers @{Authorization = "Bearer $accessToken"} -ContentType "application/json"
$oidConflictUsers = $response.Content | ConvertFrom-Json

Write-Host ""
Write-Host "Azure DevOps users to be deleted: $($oidConflictUsers.count)" -ForegroundColor Yellow
$oidConflictUsers.value | Format-Table -AutoSize -Wrap -Property principalName, mailAddress, originId
Write-Host ""

if (!$DryRun) {
  foreach ($user in $oidConflictUsers.value) {
    Write-Host "Delete/remove user $($user.principalName) ..." -ForegroundColor Yellow
    az devops user remove --org "https://dev.azure.com/$OrganizationName" --user $user.principalName
  }
}

Write-Host ""
Write-Host "EXECUTION COMPLETED" -ForegroundColor Green

return $oidConflictUsers.value
