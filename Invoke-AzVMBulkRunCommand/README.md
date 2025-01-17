# Invoke-AzVMBulkRunCommand.ps1  
**Bulk Command Execution for Azure Virtual Machines**  

---

## Overview  
The `Invoke-AzVMBulkRunCommand.ps1` script is designed to automate the execution of commands across multiple Azure Virtual Machines (VMs) efficiently. Whether you're managing Windows or Linux VMs, this script simplifies bulk operations by leveraging the Az SDK and PowerShell capabilities.  

## Prerequisites  
To use this script, you need the following:  

1. **Scripts Directory**: Ensure that a directory named `Scripts` is present in the same folder as `Invoke-AzVMBulkRunCommand.ps1`.  
2. **Required Scripts** (located in the `Scripts` directory):  
   - `Invoke-WindowsScript.ps1`: Handles the execution of commands on Windows VMs.  
   - `run_linux_script.sh`: Handles the execution of commands on Linux VMs.
  
```

```  

These supporting scripts are essential for the functionality of `Invoke-AzVMBulkRunCommand.ps1`.  

## Usage  
1. Clone or download this repository.  
2. Ensure the `Scripts` directory is in place with the required scripts (`Invoke-WindowsScript.ps1` and `run_linux_script.sh`) inside it.  
3. Open a PowerShell session.  
4. Execute the script using the following syntax:  

   ```powershell
   ./Invoke-AzVMBulkRunCommand.ps1 -Parameter1 <value> -Parameter2 <value>
