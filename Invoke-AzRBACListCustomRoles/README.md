# Invoke-AzRBACListCustomRoles.ps1  
**(PowerShell 7+) List Azure RBAC Custom Roles**
> [!NOTE]
> - Compatible with non-Windows PowerShell (pwsh)
> - Az SDK wrapper 🌯
> - Requires atleast Azure RBAC `Reader` permissions on the subscription, resource group, and resources in-scope

---

## Overview  
The `Invoke-AzRBACListCustomRoles.ps1` script is designed to automate the execution of commands all assets. This script will use Role-Base Access Control (RBAC) access to query Custom Azure RBAC configurations on Subscriptions, Resource Groups.  

## Prerequisites  
To use this script, you need the following:  

- **Az PowerShell SDK**: Authenticate with `Connect-AzAccount` before launching `Invoke-AzRBACListCustomRoles.ps1`.
- **Azure RBAC Reader**: The identity to use with the `Az SDK` requires atleast `Reader` on the subscriptions, resource group, or resource(s) in-scope.
  
## Usage  
- Clone the repo and start `pwsh`

  ```powershell
  git clone https://github.com/fjodoin/AzureRT.git
  cd ./AzureRT/Invoke-AzRBACListCustomRoles
  pwsh
  ```

  ![image](https://github.com/user-attachments/assets/0de519f1-d57e-4c11-9b1e-abe02d7a3d1b)


- Import and Run the Function

  ```powershell
  . ./Invoke-AzRBACListCustomRoles.ps1
  ./Invoke-AzRBACListCustomRoles
  ```

![image](https://github.com/user-attachments/assets/29d8d610-25e3-41d5-82d5-b3133e283236)


- Protect your assets!

![image](https://github.com/user-attachments/assets/8f5bc72b-d32a-4955-8c00-9cc23a0b67c2)







