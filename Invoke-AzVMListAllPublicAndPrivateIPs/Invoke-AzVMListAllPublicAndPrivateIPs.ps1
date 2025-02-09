function Invoke-AzVMListAllPublicAndPrivateIPs {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string[]]$SubscriptionIds,

        [Parameter(Mandatory = $false)]
        [string]$VMListFilePath
    )

    $ErrorActionPreference = 'Stop'
    Write-Host "Script execution started. Collecting data..." -ForegroundColor Green

    try {
        Import-Module -Name Az -ErrorAction Stop

        # Get all enabled subscriptions or filter by provided subscription IDs
        if ($SubscriptionIds) {
            $subscriptions = Get-AzSubscription | Where-Object { $_.State -eq 'Enabled' -and $SubscriptionIds -contains $_.Id }
        }
        else {
            $subscriptions = Get-AzSubscription | Where-Object { $_.State -eq 'Enabled' }
        }

        if (-not $subscriptions) {
            Write-Host "No enabled subscriptions found. Exiting." -ForegroundColor Yellow
            return
        }

        # Read VM names from the provided file if any
        $vmNamesToCheck = @()
        if ($VMListFilePath) {
            if (Test-Path $VMListFilePath) {
                $vmNamesToCheck = Get-Content -Path $VMListFilePath
            }
            else {
                Write-Host "VM list file not found. Exiting." -ForegroundColor Yellow
                return
            }
        }

        $results = @()

        foreach ($subscription in $subscriptions) {
            Write-Host "Processing subscription: $($subscription.Name)" -ForegroundColor Cyan

            try {
                # Switch subscription
                Select-AzSubscription -SubscriptionId $subscription.Id -ErrorAction Stop | Out-Null

                # Get VMs (with status & network profile)
                $vms = Get-AzVM -Status | Select-Object Name, ResourceGroupName, NetworkProfile, PowerState

                foreach ($vm in $vms) {
                    # Skip if a list of VMs is provided and this one is not in it
                    if ($vmNamesToCheck -and ($vmNamesToCheck -notcontains $vm.Name)) {
                        continue
                    }

                    $vmName = $vm.Name
                    $vmRG = $vm.ResourceGroupName
                    $powerState = $vm.PowerState -replace "^PowerState/", ""

                    foreach ($nicReference in $vm.NetworkProfile.NetworkInterfaces) {
                        # Parse NIC name and resource group from its ID (format: /subscriptions/.../resourceGroups/{rg}/providers/Microsoft.Network/networkInterfaces/{nicName})
                        $nicIdParts = $nicReference.Id -split '/'
                        $nicName = $nicIdParts[-1]
                        $nicRG = $nicIdParts[4]

                        $nic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $nicRG -ErrorAction SilentlyContinue
                        if (-not $nic) { continue }

                        foreach ($ipConfig in $nic.IpConfigurations) {
                            $privateIpAddress = $ipConfig.PrivateIpAddress
                            $publicIpAddress = $null

                            # Get Public IP if assigned
                            if ($ipConfig.PublicIpAddress) {
                                $publicIpIdParts = $ipConfig.PublicIpAddress.Id -split '/'
                                $publicIpName = $publicIpIdParts[-1]
                                $publicIpRG = $publicIpIdParts[4]
                                $publicIp = Get-AzPublicIpAddress -Name $publicIpName -ResourceGroupName $publicIpRG -ErrorAction SilentlyContinue
                                if ($publicIp) {
                                    $publicIpAddress = $publicIp.IpAddress
                                }
                            }

                            # Parse virtual network and subnet details from ipConfig.Subnet.Id 
                            # Expected format: /subscriptions/{subId}/resourceGroups/{rg}/providers/Microsoft.Network/virtualNetworks/{vnetName}/subnets/{subnetName}
                            $subnetIdParts = $ipConfig.Subnet.Id -split '/'
                            $vnetRG = $subnetIdParts[4]
                            $vnetName = $subnetIdParts[8]
                            $subnetName = $subnetIdParts[10]

                            # Retrieve the virtual network and then the subnet configuration
                            $vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $vnetRG -ErrorAction SilentlyContinue
                            $subnet = $vnet.Subnets | Where-Object { $_.Name -eq $subnetName }
                            $subnetRange = if ($subnet -and $subnet.AddressPrefix) { $subnet.AddressPrefix } else { "N/A" }

                            # --- Collect NSG rules from both NIC and Subnet ---
                            $nsgRulesList = @()

                            # Check if the NIC has an associated NSG
                            if ($nic.NetworkSecurityGroup) {
                                $nicNsgIdParts = $nic.NetworkSecurityGroup.Id -split '/'
                                $nicNsgName = $nicNsgIdParts[-1]
                                $nicNsgRG = $nicNsgIdParts[4]
                                $nicNsg = Get-AzNetworkSecurityGroup -Name $nicNsgName -ResourceGroupName $nicNsgRG -ErrorAction SilentlyContinue
                                if ($nicNsg) {
                                    foreach ($rule in $nicNsg.SecurityRules) {
                                        $nsgRulesList += [PSCustomObject]@{
                                            From        = "NIC"
                                            RuleName    = $rule.Name
                                            Direction   = $rule.Direction
                                            Access      = $rule.Access
                                            Protocol    = $rule.Protocol
                                            Source      = $rule.SourceAddressPrefix
                                            Destination = $rule.DestinationAddressPrefix
                                            Ports       = $rule.DestinationPortRange
                                        }
                                    }
                                }
                            }

                            # Check if the subnet has an associated NSG
                            if ($subnet -and $subnet.NetworkSecurityGroup) {
                                $subnetNsgIdParts = $subnet.NetworkSecurityGroup.Id -split '/'
                                $subnetNsgName = $subnetNsgIdParts[-1]
                                $subnetNsgRG = $subnetNsgIdParts[4]
                                $subnetNsg = Get-AzNetworkSecurityGroup -Name $subnetNsgName -ResourceGroupName $subnetNsgRG -ErrorAction SilentlyContinue
                                if ($subnetNsg) {
                                    foreach ($rule in $subnetNsg.SecurityRules) {
                                        $nsgRulesList += [PSCustomObject]@{
                                            From        = "Subnet"
                                            RuleName    = $rule.Name
                                            Direction   = $rule.Direction
                                            Access      = $rule.Access
                                            Protocol    = $rule.Protocol
                                            Source      = $rule.SourceAddressPrefix
                                            Destination = $rule.DestinationAddressPrefix
                                            Ports       = $rule.DestinationPortRange
                                        }
                                    }
                                }
                            }

                            # Aggregate the NSG rules into a formatted HTML string (or show "N/A" if none)
                            if ($nsgRulesList.Count -gt 0) {
                                $nsgRulesFormatted = $nsgRulesList | ForEach-Object {
                                    "[ $($_.From) ] $($_.RuleName): $($_.Direction) | $($_.Access) | Protocol: $($_.Protocol) | Src: $($_.Source) | Dst: $($_.Destination) | Ports: $($_.Ports)"
                                }
                                $nsgRulesAggregated = $nsgRulesFormatted -join "<br>"
                            }
                            else {
                                $nsgRulesAggregated = "N/A"
                            }

                            # Save the result for this IP configuration
                            $results += [PSCustomObject]@{
                                Subscription = $subscription.Name
                                VMName       = $vmName
                                PublicIP     = $publicIpAddress
                                PrivateIP    = $privateIpAddress
                                State        = $powerState
                                VNetName     = $vnetName
                                SubnetRange  = $subnetRange
                                NSGRules     = $nsgRulesAggregated
                            }
                        }
                    }
                }
            }
            catch {
                Write-Error "Error processing subscription $($subscription.Name): $($_.Exception.Message)"
            }
        }

        Write-Host "Generating HTML report..." -ForegroundColor Green

        # Build HTML table rows
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
            $htmlRows += "<td>$($result.NSGRules)</td>"
            $htmlRows += "</tr>"
        }

        # Construct full HTML content
        $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Azure VM Info Report: NSG Rules, Public and Private IPs</title>
    <link rel="stylesheet" href="https://cdn.datatables.net/1.13.4/css/jquery.dataTables.min.css">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; vertical-align: top; }
        th { background-color: #007FFF; color: white; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        tr:hover { background-color: #f1f1f1; }
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
    <h1 style="color: #007FFF;">Azure VM Info Report: NSG Rules, Public and Private IPs</h1>
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
                <th>NSG Rules</th>
            </tr>
        </thead>
        <tbody>
$htmlRows
        </tbody>
    </table>
</body>
</html>
"@

        # Save the HTML report and open it
        $htmlPath = "AzureVMInfoReport_PublicAndPrivateIPs.html"
        $htmlContent | Out-File -FilePath $htmlPath -Encoding UTF8
        Write-Host "Report generated: $htmlPath" -ForegroundColor Green
        Start-Process $htmlPath
    }
    catch {
        Write-Error "An error occurred: $($_.Exception.Message)"
    }
}
