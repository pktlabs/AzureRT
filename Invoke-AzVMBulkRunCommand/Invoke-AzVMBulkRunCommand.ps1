param (
    [string[]]$SubscriptionIds,
    [string]$ResourceGroup
)

<#
.SYNOPSIS
Runs custom scripts on all running Azure VMs in specified subscriptions and resource groups.

.DESCRIPTION
This script connects to the specified Azure subscriptions, retrieves all VMs that are in the "running" state, and executes either a PowerShell or Bash script depending on the operating system type of each VM. If no resource group is specified, it scans all VMs in the subscriptions.

.PARAMETER SubscriptionIds
(Optional) The IDs of the Azure subscriptions to use. If not provided, all subscriptions will be scanned.

.PARAMETER ResourceGroup
(Optional) The name of the Azure resource group containing the VMs. If not provided, all VMs in the subscriptions will be scanned.

.EXAMPLE
.\Invoke-AzVMBulkRunCommand.ps1
.\Invoke-AzVMBulkRunCommand.ps1 -SubscriptionIds <subscriptionId1>,<subscriptionId2>
.\Invoke-AzVMBulkRunCommand.ps1 -SubscriptionIds <subscriptionId1> -ResourceGroup <resourceGroup>
#>

try {
    # Validate parameters
    if (-not $SubscriptionIds) {
        # Write-Host "No subscription IDs provided. Retrieving all subscriptions..." -ForegroundColor Cyan
        $SubscriptionIds = (Get-AzSubscription).Id
    }

    foreach ($SubscriptionId in $SubscriptionIds) {
        # Set Azure subscription context
        # Write-Host "Setting Azure subscription context to $SubscriptionId..." -ForegroundColor Cyan
        Set-AzContext -Subscription $SubscriptionId -WarningAction SilentlyContinue

        # Retrieve all running VMs
        # Write-Host "Retrieving all running VMs in subscription $SubscriptionId..." -ForegroundColor Cyan
        $vms = if ($ResourceGroup) {
            Get-AzVM -ResourceGroupName $ResourceGroup -Status |
                Where-Object { $_.PowerState -eq "VM running" }
        } else {
            Get-AzVM -Status |
                Where-Object { $_.PowerState -eq "VM running" }
        }

        if (-not $vms) {
            # Write-Host "No running VMs found in subscription $SubscriptionId." -ForegroundColor Yellow
            continue
        }

        Write-Host "Found $($vms.Count) running VM(s) in subscription $SubscriptionId. Starting script execution..." -ForegroundColor Green

        # Execute scripts on each VM in parallel
        $vms | ForEach-Object -Parallel {
            Write-Host "Processing VM: $($_.Name) in subscription ${using:SubscriptionId}..." -ForegroundColor Cyan
            try {
                if ($_.StorageProfile.OSDisk.OSType -eq "Windows") {
                    # For Windows VMs, run the PowerShell script
                    $result = Invoke-AzVMRunCommand `
                        -ResourceGroupName $_.ResourceGroupName `
                        -Name $_.Name `
                        -CommandId 'RunPowerShellScript' `
                        -ScriptPath .\Scripts\Invoke-WindowsScript.ps1
                } elseif ($_.StorageProfile.OSDisk.OSType -eq "Linux") {
                    # For Linux VMs, run the Bash script
                    $result = Invoke-AzVMRunCommand `
                        -ResourceGroupName $_.ResourceGroupName `
                        -Name $_.Name `
                        -CommandId 'RunShellScript' `
                        -ScriptPath .\Scripts\run_linux_script.sh
                }

                # Format and display the output
                Write-Host "VM: $($_.Name) in subscription ${using:SubscriptionId} - Script execution successful." -ForegroundColor Green
                [PSCustomObject]@{
                    VMName   = $_.Name
                    Message  = $result.Value[0].Message
                }
            } catch {
                Write-Warning "Failed to run command on VM $($_.Name) in subscription ${using:SubscriptionId}: $_"
            }
        }
        Write-Host "Script execution completed for all VMs in subscription $SubscriptionId." -ForegroundColor Green
    }

} catch {
    Write-Error "An error occurred: $_"
}
