# Invoke-AzVMBulkRunCommand.ps1  
**Bulk Command Execution for Azure Virtual Machines**
> [!NOTE] 
> - +40% speed increase compared to sequential AzVMRunCommands
> - Az SDK wrapper 🌯

---

## Overview  
The `Invoke-AzVMBulkRunCommand.ps1` script is designed to automate the execution of commands across multiple Azure Virtual Machines (VMs) efficiently. Whether you're managing Windows or Linux VMs, this script simplifies bulk operations by leveraging the Az SDK and PowerShell capabilities.  

## Prerequisites  
To use this script, you need the following:  

1. **Az PowerShell SDK**: Authenticate with `Connect-AzAccount` before launching `Invoke-WindowsScript.ps1`.
2. **Scripts Directory**: Ensure that a directory named `Scripts` is present in the same folder as `Invoke-AzVMBulkRunCommand.ps1`.  
3. **Required Scripts** (located in the `Scripts` directory):  
   - `Invoke-WindowsScript.ps1`: Handles the execution of commands on Windows VMs.  
   - `run_linux_script.sh`: Handles the execution of commands on Linux VMs.
  
![image](https://github.com/user-attachments/assets/0e0916c7-aff5-4f6a-a0f8-8ff0c391c3db)


These supporting scripts are essential for the functionality of `Invoke-AzVMBulkRunCommand.ps1`.  

## Usage  
1. Clone or download this repository.  
2. Ensure the `Scripts` directory is in place with the required scripts (`Invoke-WindowsScript.ps1` and `run_linux_script.sh`) inside it.  
3. Adjust the `Scripts` to perform desired tasks.
4. Open a PowerShell session.  
5. Execute the script using the following syntax to execute on either (1) all VMs, (2) all VMs within specific Subscription(s), or (3) all VMs within a specific Resource Group + Subscription:  

   ```powershell
   git clone https://github.com/fjodoin/AzureRT.git
   cd Invoke-AzVMBulkRunCommand

   # Using PowerShell (pwsh) 7+   
   .\Invoke-AzVMBulkRunCommand.ps1
   .\Invoke-AzVMBulkRunCommand.ps1 -SubscriptionIds <subscriptionId1>,<subscriptionId2>
   .\Invoke-AzVMBulkRunCommand.ps1 -SubscriptionIds <subscriptionId1> -ResourceGroup <resourceGroup>
   ```
