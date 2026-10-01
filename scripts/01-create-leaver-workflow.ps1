<#
  Creates a Lifecycle Workflows "leaver" workflow through Microsoft Graph.
  Scope:   users where department = 'Contractors'
  Trigger: the user's employeeLeaveDateTime (offset 0 days)
  Tasks:   remove access package assignments -> remove from all groups -> disable account
#>

$ErrorActionPreference = "Stop"
$WorkflowName = "lcw-gavinbarbee-contractor-leaver"

Connect-MgGraph -TenantId $env:ARM_TENANT_ID -UseDeviceCode -Scopes "LifecycleWorkflows.ReadWrite.All" -NoWelcome

# Look up built-in task definitions by name instead of hard-coding IDs
$taskDefs = (Invoke-MgGraphRequest -Method GET -Uri "v1.0/identityGovernance/lifecycleWorkflows/taskDefinitions").value |
    Where-Object { $_.category -match "leaver" }

Write-Host "`nLeaver task definitions available in this tenant:" -ForegroundColor Cyan
$taskDefs | ForEach-Object { [pscustomobject]@{ DisplayName = $_.displayName; Id = $_.id } } | Format-Table -AutoSize

function Get-TaskDefinition([string]$Pattern) {
    $match = $taskDefs | Where-Object { $_.displayName -match $Pattern } | Select-Object -First 1
    if (-not $match) { throw "No leaver task definition matched '$Pattern'. Check the table above." }
    return $match
}

$removeAccessPackages = Get-TaskDefinition "Remove all access package assignments"
$removeGroups         = Get-TaskDefinition "Remove user from all groups"
$disableAccount       = Get-TaskDefinition "Disable User Account"

function New-Task($Definition) {
    @{
        category         = "leaver"
        continueOnError  = $false
        displayName      = $Definition.displayName
        description      = $Definition.description
        isEnabled        = $true
        taskDefinitionId = $Definition.id
        arguments        = @()
    }
}

$body = @{
    category            = "leaver"
    displayName         = $WorkflowName
    description         = "Offboards contractors on their leave date: removes access packages and groups, then disables the account."
    isEnabled           = $true
    isSchedulingEnabled = $false   # Lab: run on demand. In production, enable scheduling.
    executionConditions = @{
        "@odata.type" = "#microsoft.graph.identityGovernance.triggerAndScopeBasedConditions"
        scope   = @{
            "@odata.type" = "#microsoft.graph.identityGovernance.ruleBasedSubjectSet"
            rule          = "(department eq 'Contractors')"
        }
        trigger = @{
            "@odata.type"      = "#microsoft.graph.identityGovernance.timeBasedAttributeTrigger"
            timeBasedAttribute = "employeeLeaveDateTime"
            offsetInDays       = 0
        }
    }
    tasks = @(
        (New-Task $removeAccessPackages),
        (New-Task $removeGroups),
        (New-Task $disableAccount)
    )
}

$workflow = Invoke-MgGraphRequest -Method POST `
    -Uri "v1.0/identityGovernance/lifecycleWorkflows/workflows" `
    -Body ($body | ConvertTo-Json -Depth 10) `
    -ContentType "application/json"

Write-Host "`nCreated workflow '$($workflow.displayName)' with ID $($workflow.id)" -ForegroundColor Green
