# Invoke-AzSAListPublicAccess.ps1  
**(PowerShell 7+) List Azure Storage Account Container and Blob Public Access**
> [!NOTE]
> - Compatible with non-Windows PowerShell (pwsh)
> - Az SDK wrapper 🌯
> - Storage Account Network rules *may* block access; if so, run with atleast `Storage Account Contributor` Azure RBAC permissions

---

## Overview  
The `Invoke-AzSAListPublicAccess.ps1` script is designed to automate the execution of commands across multiple Azure Storage Accounts (SAs). This script will use Role-Base Access Control (RBAC) access (as opposed to Key-Authentication, as this may be disabled) to query access control configurations on Storage Account Containers and Blobs.  

## Prerequisites  
To use this script, you need the following:  

- **Az PowerShell SDK**: Authenticate with `Connect-AzAccount` before launching `Invoke-AzSAListPublicAccess.ps1`.
- **Azure RBAC Reader**: The identity to use with the `Az SDK` requires atleast "Storage Account Contributor" to run `Get-AzStorageContainerAcl` on the subscriptions, resource group, or resource(s) in-scope.
  
## Usage  
- Clone the repo and start `pwsh`

  ```powershell
  git clone https://github.com/fjodoin/AzureRT.git
  cd ./AzureRT/Invoke-AzSAListPublicAccess
  pwsh
  ```

  ![image](https://github.com/user-attachments/assets/ef41c444-dc37-4358-8e29-be660e4eb9b4)


- Import and Run the script

  ```powershell
  . ./Invoke-AzSAListPublicAccess
  Invoke-AzSAListPublicAccess
  ```

  <img width="1324" alt="image" src="https://github.com/user-attachments/assets/b998b0e5-40b6-4552-aca4-59dc8cc0104d" />

- Protect your assets!

![image](https://github.com/user-attachments/assets/f1424d3e-6a29-4c18-af8f-27e5a83847d7)






