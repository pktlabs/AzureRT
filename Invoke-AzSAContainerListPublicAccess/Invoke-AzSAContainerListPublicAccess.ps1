<#
.SYNOPSIS
    Lists the public access levels of Azure Blob containers across all subscriptions in parallel.

.DESCRIPTION
    This script connects to Azure, retrieves all enabled subscriptions, and lists the public access levels of all blob containers in each storage account within those subscriptions. It uses parallel processing to speed up execution.

.NOTES
    Author: Filip Jodoin
    Date: Jan. 20, 2025
    Version: 1.3

.EXAMPLE
    .\Invoke-AzSAContainerListPublicAccess.ps1
#>

# Connect to Azure
# Connect-AzAccount

Write-Host "Script execution started: any hits will be displayed below ..." -ForegroundColor Green

# Get the subscriptions
$subscriptions = Get-AzSubscription | Where-Object { $_.State -eq 'Enabled' }

if (-not $subscriptions) {
    Write-Host "No subscriptions found." -ForegroundColor Yellow
    return
}

# Filter out invalid subscriptions with missing IDs
$validSubscriptions = $subscriptions | Where-Object { $_.Id -ne $null -and $_.Id -ne "" }

if (-not $validSubscriptions) {
    Write-Host "No valid subscriptions found." -ForegroundColor Yellow
    return
}

# Define a script block for job processing
$scriptBlock = {
    param(
        $subscription
    )

    # Import required modules in the job
    Import-Module Az.Accounts
    Import-Module Az.Storage

    if (-not $subscription.Id) {
        Write-Host "Skipping subscription with missing ID: $($subscription.Name)" -ForegroundColor Red
        return
    }

    $null = Set-AzContext -SubscriptionId $subscription.Id

    # Get storage accounts
    $storageAccounts = Get-AzStorageAccount | Select-Object StorageAccountName, ResourceGroupName

    $resultList = @()

    if ($storageAccounts) {
        foreach ($storageAccount in $storageAccounts) {
            $accountName = $storageAccount.StorageAccountName
            $resourceGroup = $storageAccount.ResourceGroupName

            # Set the context to use EntraID authentication
            $context = New-AzStorageContext -StorageAccountName $accountName -UseConnectedAccount

            # List containers
            $containers = Get-AzStorageContainer -Context $context | Select-Object Name

            if ($containers) {
                foreach ($container in $containers) {
                    # Check public access level
                    $publicAccessLevel = (Get-AzStorageContainerAcl -Name $container.Name -Context $context).PublicAccess

                    if ($publicAccessLevel) {
                        $resultList += [PSCustomObject]@{
                            SubscriptionName    = $subscription.Name
                            StorageAccountName  = $accountName
                            ResourceGroupName   = $resourceGroup
                            ContainerName       = $container.Name
                            PublicAccessLevel   = $publicAccessLevel
                        }
                    }
                }
            }
        }
    }

    # Return the result list
    return $resultList
}

# Start jobs for each valid subscription
$jobs = @()
foreach ($subscription in $validSubscriptions) {
    $jobs += Start-Job -ScriptBlock $scriptBlock -ArgumentList $subscription
}

# Wait for all jobs to complete
Write-Host "Waiting for all jobs to complete..." -ForegroundColor Yellow
$null = $jobs | ForEach-Object { Wait-Job -Job $_ }

# Collect results from all jobs
$finalResults = @()
foreach ($job in $jobs) {
    # Check if job is completed before receiving and removing
    if ($job.State -eq 'Completed') {
        $finalResults += Receive-Job -Job $job
        # Clean up completed job
        Remove-Job -Job $job
    } else {
        Write-Host "Job with ID $($job.Id) is not finished, skipping removal." -ForegroundColor Red
    }
}

# Output results
Write-Host "Results:" -ForegroundColor Green
$finalResults | Format-Table -AutoSize

Write-Host "`nAll subscriptions processed." -ForegroundColor Green
