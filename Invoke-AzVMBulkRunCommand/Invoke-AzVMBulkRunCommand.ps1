<#
.SYNOPSIS
Runs custom scripts on specific or all running Azure VMs in specified subscriptions and resource groups.

.DESCRIPTION
This script connects to the specified Azure subscriptions, retrieves VMs based on provided parameters, and executes either a PowerShell or Bash script depending on the operating system type of each VM. If a file of VM names is provided, only those VMs are targeted.

.NOTES
    Author: Filip Jodoin
    Date: Jan. 22, 2025
    Version: 0.0

.PARAMETER SubscriptionIds
(Optional) The IDs of the Azure subscriptions to use. If not provided, all subscriptions will be scanned.

.PARAMETER ResourceGroup
(Optional) The name of the Azure resource group containing the VMs. If not provided, all VMs in the subscriptions will be scanned.

.PARAMETER VMNames
(Optional) The path to a file containing a list of VM names. If provided, only these VMs will be targeted.

.EXAMPLE
.\Invoke-AzVMBulkRunCommand.ps1
.\Invoke-AzVMBulkRunCommand.ps1 -SubscriptionIds <subscriptionId1>,<subscriptionId2>
.\Invoke-AzVMBulkRunCommand.ps1 -SubscriptionIds <subscriptionId1> -ResourceGroup <resourceGroup>
.\Invoke-AzVMBulkRunCommand.ps1 -VMNames file.txt
#>

param (
    [string[]]$SubscriptionIds,
    [string]$ResourceGroup,
    [string]$VMNames
)


try {
    # Validate parameters
    if (-not $SubscriptionIds) {
        $SubscriptionIds = (Get-AzSubscription).Id
    }

    $VMList = @()
    if ($VMNames) {
        if (-not (Test-Path -Path $VMNames)) {
            throw "The specified VM file does not exist: $VMNames"
        }
        $VMList = Get-Content -Path $VMNames
    }

    foreach ($SubscriptionId in $SubscriptionIds) {
        Set-AzContext -Subscription $SubscriptionId -WarningAction SilentlyContinue

        $vms = if ($ResourceGroup) {
            Get-AzVM -ResourceGroupName $ResourceGroup -Status |
                Where-Object { $_.PowerState -eq "VM running" }
        } else {
            Get-AzVM -Status |
                Where-Object { $_.PowerState -eq "VM running" }
        }

        if (-not $vms) {
            continue
        }

        if ($VMList.Count -gt 0) {
            $vms = $vms | Where-Object { $VMList -contains $_.Name }
        }

        Write-Host "Found $($vms.Count) running VM(s) in subscription $SubscriptionId. Starting script execution..." -ForegroundColor Green

        $vms | ForEach-Object -Parallel {
            Write-Host "Processing VM: $($_.Name) in subscription ${using:SubscriptionId}..." -ForegroundColor Cyan
            try {
                if ($_.StorageProfile.OSDisk.OSType -eq "Windows") {
                    $result = Invoke-AzVMRunCommand `
                        -ResourceGroupName $_.ResourceGroupName `
                        -Name $_.Name `
                        -CommandId 'RunPowerShellScript' `
                        -ScriptPath .\Scripts\Invoke-WindowsScript.ps1
                } elseif ($_.StorageProfile.OSDisk.OSType -eq "Linux") {
                    $result = Invoke-AzVMRunCommand `
                        -ResourceGroupName $_.ResourceGroupName `
                        -Name $_.Name `
                        -CommandId 'RunShellScript' `
                        -ScriptPath .\Scripts\run_linux_script.sh
                }

                Write-Host "VM: $($_.Name) - Script execution successful." -ForegroundColor Green
                [PSCustomObject]@{
                    VMName   = $_.Name
                    Message  = $result.Value[0].Message
                }
            } catch {
                Write-Warning "Failed to run command on VM $($_.Name): $_"
            }
        }
        Write-Host "Script execution completed for subscription $SubscriptionId." -ForegroundColor Green
    }

} catch {
    Write-Error "An error occurred: $_"
}
