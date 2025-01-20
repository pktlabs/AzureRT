<#
.SYNOPSIS
    Lists the public access levels of Azure Blob containers across all subscriptions.

.DESCRIPTION
    This script connects to Azure, retrieves all enabled subscriptions, and lists the public access levels of all blob containers in each storage account within those subscriptions.

.NOTES
    Author: Filip Jodoin
    Date: Jan. 20, 2025
    Version: 0.0

.EXAMPLE
    .\Invoke-AzBlobListPublicAccess.ps1
#>

# Connect to Azure
# Connect-AzAccount

Write-Host "Script execution started." -ForegroundColor Green

# Get the subscriptions
$subscriptions = Get-AzSubscription | Where-Object { $_.State -eq 'Enabled' }

if (-not $subscriptions) {
    Write-Host "No subscriptions found." -ForegroundColor Yellow
    return
}

# Initialize an array to hold the results
$results = @()

# Loop through each subscription
foreach ($subscription in $subscriptions) {
    $null = Set-AzContext -SubscriptionId $subscription.Id

    # Get the storage accounts
    $storageAccounts = Get-AzStorageAccount | Select-Object StorageAccountName, ResourceGroupName

    if (-not $storageAccounts) {
        continue
    }

    # Loop through each storage account
    foreach ($storageAccount in $storageAccounts) {
        $accountName = $storageAccount.StorageAccountName
        $resourceGroup = $storageAccount.ResourceGroupName

        # Set the context to use Azure AD authentication
        $context = New-AzStorageContext -StorageAccountName $accountName -UseConnectedAccount

        # List containers in the storage account
        $containers = Get-AzStorageContainer -Context $context | Select-Object Name

        if ($containers) {
            foreach ($container in $containers) {
                # Check the public access level of the container
                $publicAccessLevel = (Get-AzStorageContainerAcl -Name $container.Name -Context $context).PublicAccess

                if ($publicAccessLevel) {
                    # Create a custom object for the result
                    $result = [PSCustomObject]@{
                        SubscriptionName    = $subscription.Name
                        StorageAccountName  = $accountName
                        ResourceGroupName   = $resourceGroup
                        ContainerName       = $container.Name
                        PublicAccessLevel   = $publicAccessLevel
                    }
                    # Output Results
                    $result
                }
            }
        }
    }
}

Write-Host "`nAll subscriptions processed." -ForegroundColor Green
