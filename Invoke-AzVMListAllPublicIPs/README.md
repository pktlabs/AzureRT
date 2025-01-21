# Invoke-AzVMListAllPublicIPs.ps1  
**(PowerShell 7+) List Azure Virtual Machines with associated Public IP Addresses**
> [!NOTE]
> - Compatible with non-Windows PowerShell (pwsh)
> - Az SDK wrapper 🌯

---

## Overview  
The `Invoke-AzVMListAllPublicIPs.ps1` script is designed to automate the execution of commands across multiple Azure Virtual Machines (VMs). This script will use Role-Base Access Control (RBAC) access to query all VMs for associated Public IP addresses.  

## Prerequisites  
To use this script, you need the following:  

- **Az PowerShell SDK**: Authenticate with `Connect-AzAccount` before launching `Invoke-AzVMListAllPublicIPs.ps1`.
- **Azure RBAC Reader**: The identity to use with the `Az SDK` requires atleast "Reader" on the subscription(s), resource group(s), or resource(s) in-scope.
  
## Usage  

  ```powershell
  # 1. Clone or download this repository.
  git clone https://github.com/fjodoin/AzureRT.git

  # 2. Change into the according directory.
  cd ./AzureRT/Invoke-AzVMListAllPublicIPs

  # 3. Fire-up a PowerShell 7+ session  
  pwsh
  ```

  ![image](https://github.com/user-attachments/assets/e12868a8-1096-4aa6-8a70-4f771902acd3)


  ```powershell
  # 4. Run the script 
  .\Invoke-AzVMListAllPublicIPs.ps1
  ```

  [image]
