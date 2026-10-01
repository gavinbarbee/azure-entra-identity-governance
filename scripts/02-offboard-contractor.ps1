<#
  Simulates the HR system: stamps today's date as the contractor's leave date,
  shows their access BEFORE offboarding, then runs the leaver workflow on demand.
  Usage: .\02-offboard-contractor.ps1 -UserPrincipalName gavinbarbee-contractor@<yourtenant>.onmicrosoft.com
#>

param(
    [Parameter(Mandatory)]
    [string]$UserPrincipalName
)

$ErrorActionPreference = "Stop"
$WorkflowName = "lcw-gavinbarbee-contractor-leaver"

Connect-MgGraph -TenantId $env:ARM_TENANT_ID -UseDeviceCode -Scopes "LifecycleWorkflows.ReadWrite.All", "User.ReadWrite.All", "User-LifeCycleInfo.ReadWrite.All" -NoWelcome

$user = Invoke-MgGraphRequest -Method GET `
    -Uri "v1.0/users/$($UserPrincipalName)?`$select=id,displayName,accountEnabled,department"

# 1. Stamp the leave date (what an HR-driven provisioning flow would normally write)
$leaveDate = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddT00:00:00Z")
Invoke-MgGraphRequest -Method PATCH -Uri "v1.0/users/$($user.id)" `
    -Body (@{ employeeLeaveDateTime = $leaveDate } | ConvertTo-Json) -ContentType "application/json"
Write-Host "Set employeeLeaveDateTime for $($user.displayName) to $leaveDate" -ForegroundColor Cyan

# 2. Before state
$groups = (Invoke-MgGraphRequest -Method GET -Uri "v1.0/users/$($user.id)/memberOf").value
Write-Host "`nBEFORE offboarding" -ForegroundColor Yellow
Write-Host "  Account enabled: $($user.accountEnabled)"
Write-Host "  Group memberships: $(($groups | ForEach-Object { $_.displayName }) -join ', ')"

# 3. Run the workflow on demand for this user
$workflow = (Invoke-MgGraphRequest -Method GET -Uri "v1.0/identityGovernance/lifecycleWorkflows/workflows").value |
    Where-Object { $_.displayName -eq $WorkflowName } | Select-Object -First 1
if (-not $workflow) { throw "Workflow '$WorkflowName' not found. Run 01-create-leaver-workflow.ps1 first." }

Invoke-MgGraphRequest -Method POST `
    -Uri "v1.0/identityGovernance/lifecycleWorkflows/workflows/$($workflow.id)/activate" `
    -Body (@{ subjects = @(@{ id = $user.id }) } | ConvertTo-Json -Depth 5) `
    -ContentType "application/json"

Write-Host "`nLeaver workflow started for $($user.displayName). Give it a few minutes, then run 03-check-results.ps1." -ForegroundColor Green
