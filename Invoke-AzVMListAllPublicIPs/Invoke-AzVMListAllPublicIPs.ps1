function Invoke-AzVMListAllPublicIPs {
    <#
    .SYNOPSIS
    Retrieves the public IP addresses for all virtual machines across enabled Azure subscriptions.

    .DESCRIPTION
    This function queries all virtual machines and retrieves their associated public IP addresses,
    iterating over enabled subscriptions and network configurations where necessary.

    .OUTPUTS
    A custom PowerShell object containing the subscription names, VM names, and their corresponding public IP addresses.

    .EXAMPLE
    Invoke-AzVMListAllPublicIPs
    #>

    [CmdletBinding()]
    param ()

    try {
        # Ensure the Az module is imported
        Import-Module -Name Az -ErrorAction Stop

        # Get all enabled subscriptions
        $subscriptions = Get-AzSubscription | Where-Object { $_.State -eq 'Enabled' } | Select-Object -Property Id, Name

        if (-not $subscriptions) {
            Write-Output "No enabled subscriptions found."
            return
        }

        $results = @()

        foreach ($subscription in $subscriptions) {
            # Set context to current subscription (suppress output)
            $null = Set-AzContext -SubscriptionId $subscription.Id -ErrorAction Stop

            Write-Output "Processing subscription: $($subscription.Name)"

            # Get all VMs in the subscription
            $vms = Get-AzVM -Status

            foreach ($vm in $vms) {
                $vmName = $vm.Name
                $resourceGroupName = $vm.ResourceGroupName

                # Get NICs associated with the VM
                foreach ($nicReference in $vm.NetworkProfile.NetworkInterfaces) {
                    # Extract NIC name from the NIC reference
                    $nicName = ($nicReference.Id -split '/')[-1]

                    # Retrieve NIC details by name and resource group
                    $nic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $resourceGroupName

                    # Check for public IPs in the NIC's IP configurations
                    foreach ($ipConfig in $nic.IpConfigurations) {
                        if ($ipConfig.PublicIpAddress) {
                            # Extract public IP name from the reference
                            $publicIpName = ($ipConfig.PublicIpAddress.Id -split '/')[-1]

                            # Retrieve public IP details by name and resource group
                            $publicIp = Get-AzPublicIpAddress -Name $publicIpName -ResourceGroupName $resourceGroupName

                            $results += [PSCustomObject]@{
                                Subscription = $subscription.Name
                                VMName       = $vmName
                                PublicIP     = $publicIp.IpAddress
                            }
                        }
                    }
                }
            }
        }

        # Output results
        if ($results.Count -gt 0) {
            $results | Format-Table -AutoSize
        } else {
            Write-Output "No public IPs found for VMs in any subscription."
        }
    } catch {
        Write-Error "An error occurred: $_"
    }
}

# Example usage
Invoke-AzVMListAllPublicIPs
