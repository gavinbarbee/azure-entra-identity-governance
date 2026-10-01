<#
  Shows the workflow's processing results and the user's AFTER state.
  Usage: .\03-check-results.ps1 -UserPrincipalName gavinbarbee-contractor@<yourtenant>.onmicrosoft.com
#>

param(
    [Parameter(Mandatory)]
    [string]$UserPrincipalName
)

$ErrorActionPreference = "Stop"
$WorkflowName = "lcw-gavinbarbee-contractor-leaver"

Connect-MgGraph -TenantId $env:ARM_TENANT_ID -UseDeviceCode -Scopes "LifecycleWorkflows.Read.All", "User.Read.All" -NoWelcome

$workflow = (Invoke-MgGraphRequest -Method GET -Uri "v1.0/identityGovernance/lifecycleWorkflows/workflows").value |
    Where-Object { $_.displayName -eq $WorkflowName } | Select-Object -First 1

$results = (Invoke-MgGraphRequest -Method GET `
    -Uri "v1.0/identityGovernance/lifecycleWorkflows/workflows/$($workflow.id)/userProcessingResults").value

Write-Host "Workflow processing results:" -ForegroundColor Cyan
$results | ForEach-Object {
    [pscustomobject]@{
        Status      = $_.processingStatus
        Started     = $_.startedDateTime
        Completed   = $_.completedDateTime
        TotalTasks  = $_.totalTasksCount
        FailedTasks = $_.failedTasksCount
    }
} | Format-Table -AutoSize

$user = Invoke-MgGraphRequest -Method GET `
    -Uri "v1.0/users/$($UserPrincipalName)?`$select=id,displayName,accountEnabled"
$groups = (Invoke-MgGraphRequest -Method GET -Uri "v1.0/users/$($user.id)/memberOf").value

Write-Host "AFTER offboarding" -ForegroundColor Yellow
Write-Host "  Account enabled: $($user.accountEnabled)"
Write-Host "  Group memberships: $(if ($groups) { ($groups | ForEach-Object { $_.displayName }) -join ', ' } else { 'none' })"
