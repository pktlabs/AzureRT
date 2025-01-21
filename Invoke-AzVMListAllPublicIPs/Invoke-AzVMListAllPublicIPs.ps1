<#
.SYNOPSIS
Retrieves the public IP addresses and NSGs for all virtual machines across enabled Azure subscriptions.

.DESCRIPTION
This function queries all virtual machines and retrieves their associated public IP addresses,
iterating over enabled subscriptions and network configurations where necessary. It also provides
details such as the subscription name, VM state, VNet name, subnet range, source, destination, protocol,
and allowed ports based on associated network security group (NSG) rules.

.OUTPUTS
An HTML report displaying the subscription names, VM names, and their corresponding public IP addresses,
including additional metadata for network configurations and security rules.

.EXAMPLE
Invoke-AzVMListAllPublicIPs
# This command generates an HTML report of all virtual machines with their public IPs and network details.

.NOTES
Author: Filip Jodoin
Date: Jan. 21 2025
Version: 0.0
#>

function Invoke-AzVMListAllPublicIPs {
    [CmdletBinding()]
    param ()

    # Suppress unnecessary noise
    $ErrorActionPreference = 'Stop'

    Write-Host "Script execution started. Collecting data..." -ForegroundColor Green

    try {
        Import-Module -Name Az -ErrorAction Stop

        # Get all enabled subscriptions
        $subscriptions = Get-AzSubscription | Where-Object { $_.State -eq 'Enabled' } | Select-Object -Property Id, Name

        if (-not $subscriptions) {
            Write-Host "No enabled subscriptions found. Exiting." -ForegroundColor Yellow
            return
        }

        $results = @()

        foreach ($subscription in $subscriptions) {
            # Show which subscription is being processed
            Write-Host "Processing subscription: $($subscription.Name)" -ForegroundColor Cyan

            try {
                # Switch to the subscription quietly
                Select-AzSubscription -SubscriptionId $subscription.Id -ErrorAction Stop | Out-Null

                # Fetch all VMs with status and network profile
                $vms = Get-AzVM -Status | Select-Object Name, ResourceGroupName, NetworkProfile, PowerState

                foreach ($vm in $vms) {
                    $vmName = $vm.Name
                    $resourceGroupName = $vm.ResourceGroupName
                    $powerState = $vm.PowerState -replace "^PowerState/", "" # Clean up PowerState prefix

                    foreach ($nicReference in $vm.NetworkProfile.NetworkInterfaces) {
                        $nicName = ($nicReference.Id -split '/')[-1]
                        $nic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue

                        foreach ($ipConfig in $nic.IpConfigurations) {
                            if ($ipConfig.PublicIpAddress) {
                                # Fetch the public IP address
                                $publicIpName = ($ipConfig.PublicIpAddress.Id -split '/')[-1]
                                $publicIp = Get-AzPublicIpAddress -Name $publicIpName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue

                                # Fetch subnet details using -ResourceId
                                $subnet = Get-AzVirtualNetworkSubnetConfig -ResourceId $ipConfig.Subnet.Id -ErrorAction SilentlyContinue
                                $subnetRange = ($subnet.AddressPrefix -join ", ") # Join multiple prefixes into a single string
                                $vnetName = ($ipConfig.Subnet.Id -split '/')[8] # Extract VNet name from subnet ID

                                # Get NSG applied to the NIC or subnet
                                $nsgRules = @()
                                if ($nic.NetworkSecurityGroup) {
                                    $nsgName = ($nic.NetworkSecurityGroup.Id -split '/')[-1]
                                    $nsg = Get-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
                                    $nsgRules = $nsg.SecurityRules | Select-Object Name, Direction, Access, Protocol, SourceAddressPrefix, DestinationAddressPrefix, DestinationPortRange
                                } elseif ($ipConfig.Subnet) {
                                    if ($subnet.NetworkSecurityGroup) {
                                        $nsgName = ($subnet.NetworkSecurityGroup.Id -split '/')[-1]
                                        $nsg = Get-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
                                        $nsgRules = $nsg.SecurityRules | Select-Object Name, Direction, Access, Protocol, SourceAddressPrefix, DestinationAddressPrefix, DestinationPortRange
                                    }
                                }

                                # Process NSG rules for inbound traffic
                                $inboundRules = $nsgRules | Where-Object {
                                    $_.Direction -eq "Inbound" -and $_.Access -eq "Allow"
                                }

                                foreach ($rule in $inboundRules) {
                                    # Convert arrays to comma-separated strings
                                    $source = ($rule.SourceAddressPrefix -join ", ")
                                    $destination = ($rule.DestinationAddressPrefix -join ", ")
                                    $ports = ($rule.DestinationPortRange -join ", ")

                                    # Add each rule as a separate entry
                                    $results += [PSCustomObject]@{
                                        Subscription    = $subscription.Name
                                        VMName          = $vmName
                                        PublicIP        = $publicIp.IpAddress
                                        State           = $powerState
                                        VNetName        = $vnetName
                                        SubnetRange     = $subnetRange
                                        Source          = $source
                                        Destination     = $destination
                                        Protocol        = $rule.Protocol
                                        Ports           = $ports
                                    }
                                }
                            }
                        }
                    }
                }
            } catch {
                Write-Error "Error processing subscription $($subscription.Name): $($_.Exception.Message)"
            }
        }

    # Generate Report
    Write-Host "Generating HTML report..." -ForegroundColor Green

    # Generate table rows manually
    $htmlRows = ""
    foreach ($result in $results) {
        $htmlRows += "<tr>"
        $htmlRows += "<td>$($result.Subscription)</td>"
        $htmlRows += "<td>$($result.VMName)</td>"
        $htmlRows += "<td>$($result.PublicIP)</td>"
        $htmlRows += "<td>$($result.State)</td>"
        $htmlRows += "<td>$($result.VNetName)</td>"
        $htmlRows += "<td>$($result.SubnetRange)</td>"
        $htmlRows += "<td>$($result.Source)</td>"
        $htmlRows += "<td>$($result.Destination)</td>"
        $htmlRows += "<td>$($result.Protocol)</td>"
        $htmlRows += "<td>$($result.Ports)</td>"
        $htmlRows += "</tr>"
    }

    # Combine the HTML components
    $htmlHeader = @"
<!DOCTYPE html>
<html>
<head>
    <title>Public Azure VM Info Report</title>
    <link rel="stylesheet" href="https://cdn.datatables.net/1.13.4/css/jquery.dataTables.min.css">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #007FFF; color: white; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        tr:hover { background-color: #f1f1f1; }
        input { width: 100%; box-sizing: border-box; }
    </style>
    <script src="https://code.jquery.com/jquery-3.6.4.min.js"></script>
    <script src="https://cdn.datatables.net/1.13.4/js/jquery.dataTables.min.js"></script>
    <script>
    `$(document).ready(function () {
        // Setup - Add a text input to each header cell
        `$('#nsgTable thead tr').clone(true).appendTo('#nsgTable thead');
        `$('#nsgTable thead tr:eq(1) th').each(function (i) {
            var title = `$('#nsgTable thead tr:eq(0) th').eq(i).text();
            `$(this).html('<input type="text" placeholder="Filter ' + title + '" />');

            // Apply the search
            `$('input', this).on('keyup change', function () {
                if (table.column(i).search() !== this.value) {
                    table
                        .column(i)
                        .search(this.value)
                        .draw();
                }
            });
        });

        // Initialize DataTable
        var table = `$('#nsgTable').DataTable({
            orderCellsTop: true,
            fixedHeader: true
        });
    });
    </script>
</head>
<body>
    <h1 style="color: #007FFF;">Public Azure VM Info Report</h1>
    <table id="nsgTable" class="display" style="width:100%">
        <thead>
            <tr>
                <th>Subscription</th>
                <th>VM Name</th>
                <th>Public IP</th>
                <th>State</th>
                <th>VNet Name</th>
                <th>Subnet Range</th>
                <th>Source</th>
                <th>Destination</th>
                <th>Protocol</th>
                <th>Ports</th>
            </tr>
        </thead>
        <tbody>
$htmlRows
        </tbody>
    </table>
</body>
</html>
"@




        # Combine HTML components
        $htmlReport = $htmlHeader + $htmlTable + $htmlFooter

        # Output to an HTML file
        $htmlPath = "PublicAzureVMReport.html"
        $htmlReport | Out-File -FilePath $htmlPath -Encoding UTF8

        Write-Host "Report generated: $htmlPath" -ForegroundColor Green
        Start-Process $htmlPath
    } catch {
        Write-Error "An error occurred: $($_.Exception.Message)"
    }
}
