# Invoke-AzVMInfo.ps1  
**(PowerShell 7+) List Azure Virtual Machines with associated Public IP Addresses**
> [!NOTE]
> - Compatible with non-Windows PowerShell (pwsh)
> - Az SDK wrapper 🌯
> - Azure RBAC `Reader` on the subscription, resoure group, or resources in-scope

---

## Overview  
The `Invoke-AzVMInfo.ps1` script is designed to automate the execution of commands across multiple Azure Virtual Machines (VMs). This script will use Role-Base Access Control (RBAC) access to query all VMs for associated Public IP addresses.  

## Prerequisites  
To use this script, you need the following:  

- **Az PowerShell SDK**: Authenticate with `Connect-AzAccount` before launching `Invoke-AzVMInfo.ps1`.
- **Azure RBAC Reader**: The identity to use with the `Az SDK` requires atleast "Reader" on the subscription(s), resource group(s), or resource(s) in-scope.
  
## Usage  

```powershell
# 1. Clone or download this repository.
git clone https://github.com/fjodoin/AzureRT.git

# 2. Change into the according directory.
cd ./AzureRT/Invoke-AzVMInfo

# 3. Fire-up a PowerShell 7+ session  
pwsh
```

![image](https://github.com/user-attachments/assets/9e3c7bd9-6a4b-4077-8d63-cc00a9dcf70a)


```powershell
# 4. Load the function 
. ./Invoke-AzVMInfo.ps1

# 5. Run the function
Invoke-AzVMInfo
```

![image](https://github.com/user-attachments/assets/6c3a0698-0421-41c5-a87f-409ad4c6b63e)



```powershell
# 6. Investigate your Azure VM network info report!
```

 ![image](https://github.com/user-attachments/assets/7135075c-638c-4b8a-9009-b154bca21a00)

 ![image](https://github.com/user-attachments/assets/b42c0528-8083-442c-b873-871ba9de7640)







  
