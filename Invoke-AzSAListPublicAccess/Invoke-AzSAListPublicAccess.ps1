<#
.SYNOPSIS
    Lists the public access levels of Azure Blob containers for specified subscriptions and generates an HTML report.

.DESCRIPTION
    This script connects to Azure, retrieves specified subscriptions (or all enabled ones if none are provided), 
    and lists the public access levels of all blob containers in each storage account within those subscriptions. 
    It generates an HTML report with the results, marking any failed storage account queries as "Failed" or, in the 
    case of a 403 error, as "Inconclusive: insufficient permissions".
    
.PARAMETER SubscriptionIds
    Optional. Specifies one or more Subscription IDs to filter the scan.

.NOTES
    Author: Filip Jodoin (modified by ChatGPT)
    Date: Feb. 08, 2025
    Version: 0.4
#>

param(
    [string[]]$SubscriptionIds
)

# Uncomment the next line if you need to log in to Azure
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
# Process each subscription concurrently (requires PowerShell 7+)
# ============================================================
$finalResults = $validSubscriptions | ForEach-Object -Parallel {
    # Import required modules in the parallel runspace
    Import-Module Az.Accounts -ErrorAction Stop
    Import-Module Az.Storage -ErrorAction Stop

    # Capture the subscription name for use in error handling
    $subscriptionName = $_.Name

    if (-not $_.Id) {
        Write-Host "Skipping subscription with missing ID: $subscriptionName" -ForegroundColor Red
        return
    }
    
    # Switch context to the current subscription
    Set-AzContext -SubscriptionId $_.Id | Out-Null

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

                # Retrieve the list of blob containers; force errors to be terminating.
                $containers = Get-AzStorageContainer -Context $context -ErrorAction Stop | Select-Object Name

                if ($containers) {
                    foreach ($container in $containers) {
                        try {
                            # Retrieve the container’s ACL and force errors to be terminating.
                            $containerAcl = Get-AzStorageContainerAcl -Name $container.Name -Context $context -ErrorAction Stop
                            $publicAccessLevel = $containerAcl.PublicAccess

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

                            $subResults += [PSCustomObject]@{
                                SubscriptionName    = $subscriptionName
                                StorageAccountName  = $accountName
                                ResourceGroupName   = $resourceGroup
                                ContainerName       = $container.Name
                                AnonymousAccessType = $publicAccessLevel
                            }

                            # Output a progress message if a publicly accessible container is found.
                            if ($publicAccessLevel -ne "None") {
                                Write-Host "=== Public Storage Found ===`n[+] Subscription '$subscriptionName' `n[+] Storage Account '$accountName' `n[+] Container '$($container.Name)' has public access level:" -ForegroundColor Green
                                Write-Host "$publicAccessLevel`n" -ForegroundColor Red
                            }
                        }
                        catch {
                            # Catch errors from Get-AzStorageContainerAcl
                            $errorMessage = $_.Exception.Message
                            if ($errorMessage -match "403" -or $errorMessage -match "AuthorizationFailure") {
                                $anonAccess = "Inconclusive: insufficient permissions"
                            }
                            else {
                                $anonAccess = "Failed"
                            }
                            $subResults += [PSCustomObject]@{
                                SubscriptionName    = $subscriptionName
                                StorageAccountName  = $accountName
                                ResourceGroupName   = $resourceGroup
                                ContainerName       = $container.Name
                                AnonymousAccessType = $anonAccess
                            }
                        }
                    }
                }
            }
            catch {
                # Catch errors from Get-AzStorageContainer or other storage account level issues.
                $errorMessage = $_.Exception.Message
                if ($errorMessage -match "403" -or $errorMessage -match "AuthorizationFailure") {
                    $anonAccess = "Inconclusive: insufficient permissions"
                }
                else {
                    $anonAccess = "Failed"
                }
                $subResults += [PSCustomObject]@{
                    SubscriptionName    = $subscriptionName
                    StorageAccountName  = $storageAccount.StorageAccountName
                    ResourceGroupName   = $storageAccount.ResourceGroupName
                    ContainerName       = "N/A"
                    AnonymousAccessType = $anonAccess
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
    <title>Azure Storage Account Public Access Report</title>

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
$htmlPath = "AzureSAPublicAccessReport.html"
$htmlContent | Out-File -FilePath $htmlPath -Encoding UTF8
Write-Host "Report generated: $htmlPath" -ForegroundColor Green
Start-Process $htmlPath
