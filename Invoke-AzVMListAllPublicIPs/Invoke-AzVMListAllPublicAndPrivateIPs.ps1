function Invoke-AzVMListAllPublicAndPrivateIPs {
    [CmdletBinding()]
    param ()

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
            Write-Host "Processing subscription: $($subscription.Name)" -ForegroundColor Cyan

            try {
                Select-AzSubscription -SubscriptionId $subscription.Id -ErrorAction Stop | Out-Null

                # Fetch all VMs with status and network profile
                $vms = Get-AzVM -Status | Select-Object Name, ResourceGroupName, NetworkProfile, PowerState

                foreach ($vm in $vms) {
                    $vmName = $vm.Name
                    $resourceGroupName = $vm.ResourceGroupName
                    $powerState = $vm.PowerState -replace "^PowerState/", ""

                    foreach ($nicReference in $vm.NetworkProfile.NetworkInterfaces) {
                        $nicName = ($nicReference.Id -split '/')[-1]
                        $nic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue

                        foreach ($ipConfig in $nic.IpConfigurations) {
                            $publicIpAddress = $null
                            $privateIpAddress = $ipConfig.PrivateIpAddress

                            if ($ipConfig.PublicIpAddress) {
                                $publicIpName = ($ipConfig.PublicIpAddress.Id -split '/')[-1]
                                $publicIp = Get-AzPublicIpAddress -Name $publicIpName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
                                $publicIpAddress = $publicIp.IpAddress
                            }

                            $subnet = Get-AzVirtualNetworkSubnetConfig -ResourceId $ipConfig.Subnet.Id -ErrorAction SilentlyContinue
                            $subnetRange = ($subnet.AddressPrefix -join ", ")
                            $vnetName = ($ipConfig.Subnet.Id -split '/')[8]

                            # Get NSG rules
                            $nsgRules = @()
                            if ($nic.NetworkSecurityGroup) {
                                $nsgName = ($nic.NetworkSecurityGroup.Id -split '/')[-1]
                                $nsg = Get-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
                                $nsgRules = $nsg.SecurityRules | Select-Object Name, Direction, Access, Protocol, SourceAddressPrefix, DestinationAddressPrefix, DestinationPortRange
                            } elseif ($subnet.NetworkSecurityGroup) {
                                $nsgName = ($subnet.NetworkSecurityGroup.Id -split '/')[-1]
                                $nsg = Get-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $resourceGroupName -ErrorAction SilentlyContinue
                                $nsgRules = $nsg.SecurityRules | Select-Object Name, Direction, Access, Protocol, SourceAddressPrefix, DestinationAddressPrefix, DestinationPortRange
                            }

                            $inboundRules = $nsgRules | Where-Object {
                                $_.Direction -eq "Inbound" -and $_.Access -eq "Allow"
                            }

                            foreach ($rule in $inboundRules) {
                                $source = ($rule.SourceAddressPrefix -join ", ")
                                $destination = ($rule.DestinationAddressPrefix -join ", ")
                                $ports = ($rule.DestinationPortRange -join ", ")

                                $results += [PSCustomObject]@{
                                    Subscription    = $subscription.Name
                                    VMName          = $vmName
                                    PublicIP        = $publicIpAddress
                                    PrivateIP       = $privateIpAddress
                                    State           = $powerState
                                    VNetName        = $vnetName
                                    SubnetRange     = $subnetRange
                                    Source          = $source
                                    Destination     = $destination
                                    Protocol        = $rule.Protocol
                                    Ports           = $ports
                                }
                            }

                            if (-not $inboundRules) {
                                $results += [PSCustomObject]@{
                                    Subscription    = $subscription.Name
                                    VMName          = $vmName
                                    PublicIP        = $publicIpAddress
                                    PrivateIP       = $privateIpAddress
                                    State           = $powerState
                                    VNetName        = $vnetName
                                    SubnetRange     = $subnetRange
                                    Source          = "N/A"
                                    Destination     = "N/A"
                                    Protocol        = "N/A"
                                    Ports           = "N/A"
                                }
                            }
                        }
                    }
                }
            } catch {
                Write-Error "Error processing subscription $($subscription.Name): $($_.Exception.Message)"
            }
        }

        Write-Host "Generating HTML report..." -ForegroundColor Green

        # Generate table rows manually
        $htmlRows = ""
        foreach ($result in $results) {
            $htmlRows += "<tr>"
            $htmlRows += "<td>$($result.Subscription)</td>"
            $htmlRows += "<td>$($result.VMName)</td>"
            $htmlRows += "<td>$($result.PublicIP)</td>"
            $htmlRows += "<td>$($result.PrivateIP)</td>"
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
    <title>Azure VM Info Report: Public and Private IPs</title>
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
        `$('#nsgTable').DataTable({
            orderCellsTop: true,
            fixedHeader: true
        });
    });
    </script>
</head>
<body>
    <h1 style="color: #007FFF;">Azure VM Info Report: Public and Private IPs</h1>
    <table id="nsgTable" class="display" style="width:100%">
        <thead>
            <tr>
                <th>Subscription</th>
                <th>VM Name</th>
                <th>Public IP</th>
                <th>Private IP</th>
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

        # Save and display the HTML report
        $htmlPath = "AzureVMInfoReport_PublicAndPrivateIPs.html"
        $htmlHeader | Out-File -FilePath $htmlPath -Encoding UTF8
        Write-Host "Report generated: $htmlPath" -ForegroundColor Green
        Start-Process $htmlPath

    } catch {
        Write-Error "An error occurred: $($_.Exception.Message)"
    }
}
