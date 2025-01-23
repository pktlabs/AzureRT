# Invoke-AzSAContainerListPublicAccess.ps1  
**(PowerShell 7+) List Azure Storage Account Container and Blob Public Access**
> [!NOTE]
> - Compatible with non-Windows PowerShell (pwsh)
> - Az SDK wrapper 🌯

---

## Overview  
The `Invoke-AzSAContainerListPublicAccess.ps1` script is designed to automate the execution of commands across multiple Azure Storage Accounts (SAs). This script will use Role-Base Access Control (RBAC) access (as opposed to Key-Authentication, as this may be disabled) to query access control configurations on Storage Account Containers and Blobs.  

## Prerequisites  
To use this script, you need the following:  

- **Az PowerShell SDK**: Authenticate with `Connect-AzAccount` before launching `Invoke-AzSAContainerListPublicAccess.ps1`.
- **Azure RBAC Storage Blob Reader**: The identity to use with the `Az SDK` requires atleast "Storage Blob Reader" on the subscriptions, resource group, or resource(s) in-scope.
  
## Usage  
1. Clone or download this repository.  
2. Change into the according directory.  
3. Fire-up a PowerShell 7+ session  

   ```powershell
   git clone https://github.com/fjodoin/AzureRT.git
   cd ./AzureRT/Invoke-AzSAContainerListPublicAccess
   pwsh
   ```

   ![image](https://github.com/user-attachments/assets/7421624a-0d53-4d9f-86eb-cf3370624d42)


- Run the script

   ```powershell
   .\Invoke-AzSAContainerListPublicAccess.ps1
   ```

   ![image](https://github.com/user-attachments/assets/3b37adbd-490d-4d23-96ab-5a35a9d655e5)



