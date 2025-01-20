# Invoke-AzBlobListPublicAccess.ps1  
**(PowerShell 7+) List Azure Storage Account Container and Blob Public Access**
> [!NOTE]
> - Compatible with non-Windows PowerShell (pwsh)
> - Az SDK wrapper 🌯

---

## Overview  
The `Invoke-AzBlobListPublicAccess.ps1` script is designed to automate the execution of commands across multiple Azure Storage Accounts (SAs). This script will use Role-Base Access Control (RBAC) access (as opposed to Key-Authentication, as this may be disabled) to query access control configurations on Storage Account Containers and Blobs.  

## Prerequisites  
To use this script, you need the following:  

- **Az PowerShell SDK**: Authenticate with `Connect-AzAccount` before launching `Invoke-AzBlobListPublicAccess.ps1`.
  
## Usage  
1. Clone or download this repository.  
2. Change into the according directory.  
3. Fire-up a PowerShell 7+ session  

   ```powershell
   git clone https://github.com/fjodoin/AzureRT.git
   cd ./AzureRT/Invoke-AzBlobListPublicAccess
   pwsh
   ```

   ![image](https://github.com/user-attachments/assets/7509e3c9-a565-4077-a992-8a248f322b6b)

- Run the script

   ```powershell
   .\Invoke-AzBlobListPublicAccess.ps1
   ```

   ![image](https://github.com/user-attachments/assets/e5a6a567-220f-464c-adec-9d648d657ec0)


