$pat = "AZ_DEVOPS_SERVICES_PAT_HERE" # Scopes: Build (Read)
$base64encodedPAT = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("`:$pat"))
 
$response = Invoke-RestMethod -Method Get -Uri "https://dev.azure.com/{organization}/{project}/_apis/build/workitems?fromBuildId={fromBuildId}&toBuildId={toBuildId}&api-version=7.0" -Headers @{'Authorization' = "Basic $base64encodedPAT" }
 
# Additional PAT scope needed (Work Items (Read))
foreach ($wi in $response.value) {
    $uri = "https://dev.azure.com/{organization}/{project}/_apis/wit/workItems/{0}?api-version=7.1-preview.3" -f $wi.id
    $workItem = Invoke-RestMethod -Method Get -Uri $uri -Headers @{'Authorization' = "Basic $base64encodedPAT" }
 
    Write-Host $workItem.fields.'System.WorkItemType'
    Write-Host $workItem.fields.'System.Title'
    Write-Host $workItem.url
    Write-Host $workItem.id
    Write-Host ""
}
