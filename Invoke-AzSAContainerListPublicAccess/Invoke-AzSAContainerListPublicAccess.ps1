<#
.SYNOPSIS
    Lists the public access levels of Azure Blob containers for specified subscriptions and generates an HTML report.

.DESCRIPTION
    This script connects to Azure, retrieves specified subscriptions (or all enabled ones if none are provided), 
    and lists the public access levels of all blob containers in each storage account within those subscriptions. 
    It generates an HTML report with the results, marking any failed storage account queries as "Failed".

.PARAMETER SubscriptionIds
    Optional. Specifies one or more Subscription IDs to filter the scan.

.NOTES
    Author: Filip Jodoin
    Date: Jan. 20, 2025
    Version: 0.3

.EXAMPLE
    .\Invoke-AzSAContainerListPublicAccess.ps1 -SubscriptionIds "sub-id-1","sub-id-2"
#>

param(
    [string[]]$SubscriptionIds
)

# Connect to Azure
# Connect-AzAccount

Write-Host "Script execution started: any hits will be displayed below ..." -ForegroundColor Green

# Get the subscriptions
$subscriptions = Get-AzSubscription | Where-Object { $_.State -eq 'Enabled' }

if (-not $subscriptions) {
    Write-Host "No subscriptions found." -ForegroundColor Yellow
    return
}

# If Subscription IDs were provided, filter the list
if ($SubscriptionIds) {
    $subscriptions = $subscriptions | Where-Object { $_.Id -in $SubscriptionIds }
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

    Import-Module Az.Accounts
    Import-Module Az.Storage

    if (-not $subscription.Id) {
        Write-Host "Skipping subscription with missing ID: $($subscription.Name)" -ForegroundColor Red
        return
    }

    $null = Set-AzContext -SubscriptionId $subscription.Id

    $storageAccounts = Get-AzStorageAccount | Select-Object StorageAccountName, ResourceGroupName
    $resultList = @()

    if ($storageAccounts) {
        foreach ($storageAccount in $storageAccounts) {
            try {
                $accountName = $storageAccount.StorageAccountName
                $resourceGroup = $storageAccount.ResourceGroupName
                $context = New-AzStorageContext -StorageAccountName $accountName -UseConnectedAccount
                $containers = Get-AzStorageContainer -Context $context | Select-Object Name
                if ($containers) {
                    foreach ($container in $containers) {
                        $publicAccessLevel = (Get-AzStorageContainerAcl -Name $container.Name -Context $context).PublicAccess
                        if (-not $publicAccessLevel) {
                            $publicAccessLevel = "None"
                        } elseif ($publicAccessLevel -eq "Blob") {
                            $publicAccessLevel = "Blob"
                        } elseif ($publicAccessLevel -eq "Container") {
                            $publicAccessLevel = "Container"
                        } else {
                            $publicAccessLevel = "Unknown ($publicAccessLevel)"
                        }

                        $resultList += [PSCustomObject]@{
                            SubscriptionName      = $subscription.Name
                            StorageAccountName    = $accountName
                            ResourceGroupName     = $resourceGroup
                            ContainerName         = $container.Name
                            AnonymousAccessType   = $publicAccessLevel
                        }
                    }
                }
            } catch {
                $resultList += [PSCustomObject]@{
                    SubscriptionName    = $subscription.Name
                    StorageAccountName  = $storageAccount.StorageAccountName
                    ResourceGroupName   = $storageAccount.ResourceGroupName
                    ContainerName       = "N/A"
                    AnonymousAccessType   = "Failed"
                }
            }
        }
    }
    return $resultList
}

$jobs = @()
foreach ($subscription in $validSubscriptions) {
    $jobs += Start-Job -ScriptBlock $scriptBlock -ArgumentList $subscription
}

Write-Host "Waiting for all jobs to complete..." -ForegroundColor Yellow
$null = $jobs | ForEach-Object { Wait-Job -Job $_ }

$finalResults = @()
foreach ($job in $jobs) {
    if ($job.State -eq 'Completed') {
        $finalResults += Receive-Job -Job $job
        Remove-Job -Job $job
    } else {
        Write-Host "Job with ID $($job.Id) is not finished, skipping removal." -ForegroundColor Red
    }
}

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
                colReorder: true,       // Enable column reordering
                fixedHeader: true,      // Keep header fixed while scrolling
                paging: true,           // Enable pagination
                searching: true,        // Enable search/filter functionality
                responsive: true,       // Make table responsive
                order: [[0, "asc"]],    // Default sort by Subscription Name
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
    <h1 style="color: #007FFF;">Azure Blob Public Access Report</h1>
    
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



$htmlPath = "AzureBlobPublicAccessReport.html"
$htmlContent | Out-File -FilePath $htmlPath -Encoding UTF8
Write-Host "Report generated: $htmlPath" -ForegroundColor Green
Start-Process $htmlPath
