<#
.SYNOPSIS
    Lists the public access levels of Azure Blob containers for specified subscriptions and generates an HTML report.

.DESCRIPTION
    This script connects to Azure, retrieves specified subscriptions (or all enabled ones if none are provided), 
    and lists the public access levels of all blob containers in each storage account within those subscriptions. 
    It generates an HTML report with the results, marking any failed storage account queries as "Failed" or, 
    if the error is due to network restrictions, "Inconclusive: Network Restrictions in-place".  
    It also outputs a “HIT” message to the console every time a container with public access is discovered.

.PARAMETER SubscriptionIds
    Optional. Specifies one or more Subscription IDs to filter the scan.

.NOTES
    Author: Filip Jodoin (modified by ChatGPT)
    Date: Feb. 08, 2025
    Version: 0.5
#>

param(
    [string[]]$SubscriptionIds
)

# Uncomment this line if you need to log in to Azure
# Connect-AzAccount

Write-Host "Script execution started: any HITs will be displayed below ..." -ForegroundColor Green

# Get all enabled subscriptions
$subscriptions = Get-AzSubscription | Where-Object { $_.State -eq 'Enabled' }

if (-not $subscriptions) {
    Write-Host "No subscriptions found." -ForegroundColor Yellow
    return
}

# If SubscriptionIds were provided, filter the list
if ($SubscriptionIds) {
    $subscriptions = $subscriptions | Where-Object { $_.Id -in $SubscriptionIds }
}

# Filter out any subscriptions with missing IDs
$validSubscriptions = $subscriptions | Where-Object { $_.Id -and ($_.Id -ne "") }

if (-not $validSubscriptions) {
    Write-Host "No valid subscriptions found." -ForegroundColor Yellow
    return
}

# ============================================================
# Use ForEach-Object -Parallel to process each subscription concurrently.
# (Requires PowerShell 7 or later)
# ============================================================
$finalResults = $validSubscriptions | ForEach-Object -Parallel {
    # Save the subscription object to another variable since $_ will change in catch blocks.
    $subscriptionObj = $_
    
    # Import required modules in the parallel runspace
    Import-Module Az.Accounts -ErrorAction Stop
    Import-Module Az.Storage -ErrorAction Stop

    # If for some reason the subscription object is missing an ID, skip it.
    if (-not $subscriptionObj.Id) {
        Write-Host "Skipping subscription with missing ID: $($subscriptionObj.Name)" -ForegroundColor Red
        return
    }
    
    # Switch context to the current subscription
    Set-AzContext -SubscriptionId $subscriptionObj.Id | Out-Null

    # Get all storage accounts in the subscription
    $storageAccounts = Get-AzStorageAccount | Select-Object StorageAccountName, ResourceGroupName
    $subResults = @()

    if ($storageAccounts) {
        foreach ($storageAccount in $storageAccounts) {
            try {
                $accountName = $storageAccount.StorageAccountName
                $resourceGroup = $storageAccount.ResourceGroupName

                # Create a storage context using the connected account
                $context = New-AzStorageContext -StorageAccountName $accountName -UseConnectedAccount

                # Retrieve the list of blob containers.
                # Adding -ErrorAction Stop ensures that any errors (like network restrictions) are caught.
                $containers = Get-AzStorageContainer -Context $context -ErrorAction Stop | Select-Object Name
                if ($containers) {
                    foreach ($container in $containers) {
                        # Get the container’s public access level.
                        $publicAccessLevel = (Get-AzStorageContainerAcl -Name $container.Name -Context $context -ErrorAction Stop).PublicAccess
                        if (-not $publicAccessLevel) {
                            $publicAccessLevel = "None"
                        }
                        elseif ($publicAccessLevel -eq "Blob") {
                            $publicAccessLevel = "Blob"
                        }
                        elseif ($publicAccessLevel -eq "Container") {
                            $publicAccessLevel = "Container"
                        }
                        else {
                            $publicAccessLevel = "Unknown ($publicAccessLevel)"
                        }

                        # Build the result object.
                        $resultObj = [PSCustomObject]@{
                            SubscriptionName    = $subscriptionObj.Name
                            StorageAccountName  = $accountName
                            ResourceGroupName   = $resourceGroup
                            ContainerName       = $container.Name
                            AnonymousAccessType = $publicAccessLevel
                        }
                        $subResults += $resultObj

                        # If the container is publicly accessible (a "HIT"), output a progress message.
                        if ($publicAccessLevel -ne "None") {
                            Write-Host "=== Public Storage Found ===`n[+] Subscription '$($subscriptionObj.Name)' `n[+] Storage Account '$accountName' `n[+] Container '$($container.Name)' has public access level:" -ForegroundColor Green
                            Write-Host "$publicAccessLevel`n" -ForegroundColor Red
                        }
                    }
                }
            }
            catch {
                # Check the exception message.
                $errorMessage = $_.Exception.Message
                if ($errorMessage -match "AuthorizationFailure") {
                    $accessResult = "Inconclusive: Network restrictions in-place"
                }
                else {
                    $accessResult = "Failed"
                }
                $subResults += [PSCustomObject]@{
                    SubscriptionName    = $subscriptionObj.Name
                    StorageAccountName  = $storageAccount.StorageAccountName
                    ResourceGroupName   = $storageAccount.ResourceGroupName
                    ContainerName       = "N/A"
                    AnonymousAccessType = $accessResult
                }
            }
        }
    }
    return $subResults
} -ThrottleLimit 5

# ============================================================
# Generate the HTML report.
# ============================================================
$htmlRows = ""
foreach ($result in $finalResults) {
    $htmlRows += "<tr>"
    $htmlRows += "<td>$($result.SubscriptionName)</td>"
    $htmlRows += "<td>$($result.StorageAccountName)</td>"
    $htmlRows += "<td>$($result.ResourceGroupName)</td>"
    $htmlRows += "<td>$($result.ContainerName)</td>"
    $htmlRows += "<td>$($result.AnonymousAccessType)</td>"
    $htmlRows += "</tr>"
}

$htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Azure Blob Public Access Report</title>

    <!-- DataTables CSS -->
    <link rel="stylesheet" href="https://cdn.datatables.net/1.13.4/css/jquery.dataTables.min.css">
    <link rel="stylesheet" href="https://cdn.datatables.net/colreorder/1.6.2/css/colReorder.dataTables.min.css">
    <link rel="stylesheet" href="https://cdn.datatables.net/responsive/2.4.1/css/responsive.dataTables.min.css">
    
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { width: 100% !important; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #007FFF; color: white; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        tr:hover { background-color: #f1f1f1; }
        
        /* Ensure the table container is responsive */
        .table-container {
            width: 100%;
            overflow-x: auto;
        }
    </style>

    <!-- jQuery and DataTables -->
    <script src="https://code.jquery.com/jquery-3.6.4.min.js"></script>
    <script src="https://cdn.datatables.net/1.13.4/js/jquery.dataTables.min.js"></script>
    <script src="https://cdn.datatables.net/colreorder/1.6.2/js/dataTables.colReorder.min.js"></script>
    <script src="https://cdn.datatables.net/responsive/2.4.1/js/dataTables.responsive.min.js"></script>

    <script>
        `$(document).ready(function () {
            `$('#blobTable').DataTable({
                colReorder: true,
                fixedHeader: true,
                paging: true,
                searching: true,
                responsive: true,
                order: [[0, "asc"]],
                columnDefs: [
                    { width: '20%', targets: 0 },
                    { width: '20%', targets: 1 },
                    { width: '20%', targets: 2 },
                    { width: '20%', targets: 3 },
                    { width: '20%', targets: 4 }
                ]
            });
        });
    </script>

</head>
<body>
    <h1 style="color: #007FFF;">🪣 Azure Storage Account Access Report 📝</h1>
    
    <div class="table-container">
        <table id="blobTable" class="display nowrap">
            <thead>
                <tr>
                    <th>Subscription</th>
                    <th>Storage Account</th>
                    <th>Resource Group</th>
                    <th>Container Name</th>
                    <th>Public Access Level</th>
                </tr>
            </thead>
            <tbody>
$htmlRows
            </tbody>
        </table>
    </div>

</body>
</html>
"@

# Save the report to disk and launch it in the default browser.
$htmlPath = "AzureBlobPublicAccessReport.html"
$htmlContent | Out-File -FilePath $htmlPath -Encoding UTF8
Write-Host "Report generated: $htmlPath" -ForegroundColor Green
Start-Process $htmlPath
