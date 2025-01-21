# Invoke-AzVMBulkRunCommand.ps1  
**(PowerShell 7+) Bulk Command Execution for Azure Virtual Machines**
> [!NOTE]
> - Compatible with non-Windows PowerShell (pwsh)
> - Significant speed increase compared to sequential AzVMRunCommand execution
> - Az SDK wrapper 🌯
> - Inspired by @kfosaaen's work on Microburst (Windows-Native Toolkit) [https://github.com/NetSPI/MicroBurst/commits?author=kfosaaen](https://github.com/NetSPI/MicroBurst/blob/master/AzureRM/Invoke-AzureRmVMBulkCMD.ps1)

---

## Overview  
The `Invoke-AzVMBulkRunCommand.ps1` script is designed to automate the execution of commands across multiple Azure Virtual Machines (VMs) efficiently. Whether you're managing Windows or Linux VMs, this script simplifies bulk operations by leveraging the Az SDK and PowerShell capabilities.  

## Prerequisites  
To use this script, you need the following:  

1. **Az PowerShell SDK**: Authenticate with `Connect-AzAccount` before launching `Invoke-AzVMBulkRunCommand.ps1`.
2. **Azure RBAC VM Contributor or RunCommand rights**: The identity to use with the `Az SDK` requires atleast the `"Microsoft.Compute/virtualMachines/runCommands/action"` permission, or a contributor-type role such as `"Virtual Machine Contributor"` or `"Contributor"`, on the subscriptions, resource groups, or resources in-scope.
3. **Scripts Directory**: Ensure that a directory named `Scripts` is present in the same folder as `Invoke-AzVMBulkRunCommand.ps1`.  
4. **Required Scripts** (located in the `Scripts` directory):  
   - `Invoke-WindowsScript.ps1`: Handles the execution of commands on Windows VMs.  
   - `run_linux_script.sh`: Handles the execution of commands on Linux VMs.
  
![image](https://github.com/user-attachments/assets/0e0916c7-aff5-4f6a-a0f8-8ff0c391c3db)


These supporting scripts are essential for the functionality of `Invoke-AzVMBulkRunCommand.ps1`; templates are included in the repository.  

## Usage  
1. Clone or download this repository.  
2. Change into the according directory.  
3. (Optional) Adjust the `Scripts` to perform desired tasks.
4. Fire-up a PowerShell 7+ session  

   ```powershell
   git clone https://github.com/fjodoin/AzureRT.git
   cd ./AzureRT/Invoke-AzVMBulkRunCommand
   pwsh
   ```

   ![image](https://github.com/user-attachments/assets/9b37ad3a-f423-4ab6-b887-7856aa597a41)

5. Run the script using the following syntax to execute on either;
   - (1) all VMs;
   - (2) all VMs within a specific or several Subscriptions; or
   - (3) all VMs within a specific Resource Group + Subscription.

   ```powershell
   .\Invoke-AzVMBulkRunCommand.ps1
   .\Invoke-AzVMBulkRunCommand.ps1 -SubscriptionIds <subscriptionId1>,<subscriptionId2>
   .\Invoke-AzVMBulkRunCommand.ps1 -SubscriptionIds <subscriptionId1> -ResourceGroup <resourceGroup>
   ```

   ![image](https://github.com/user-attachments/assets/8a512b7c-85c5-4ab1-a173-4ba68c1863e1)

