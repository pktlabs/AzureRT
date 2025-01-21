# A.R.G. - azure_resource_graph.py
> [!NOTE]
> - Compatible with Python 3.12+
> - Sheds light on Azurehound blindspots
> - `az cli` wrapper 🌯
> - Inspired by @andyrobbins work on [AzureHound](https://github.com/SpecterOps/AzureHound)

---

## Overview  
The `build_azure_resource_graph.py` script is designed build a graph-view of Node-Edge relationships across multiple Azure resources to help shed light on potential blindspots, such as Azure Key Vault "Access Policies", and Storage Account Access Control.  

## Prerequisites  
To use this script, you need the following:

- **az cli**: Authenticate with `az login` before launching `build_azure_resource_graph.py`.

## Usage  
1. Clone or download this repository.  
2. Change into the according directory.  
3. Fire-up a Python3 virtual environment
4. Install all the dependies

   ```powershell
   git clone https://github.com/fjodoin/AzureRT.git
   cd ./AzureRT/azure_resource_graph
   python3 -m venv arg_venv
   python3 -m pip install -r requirements.txt
   ```

   [image]

5. Run the script:
   
   ```powershell
   .\build_azure_resource_graph.py
   .\build_azure_resource_graph.py -SubscriptionIds <subscriptionId1>,<subscriptionId2>
   .\build_azure_resource_graph.py -SubscriptionIds <subscriptionId1> -ResourceGroup <resourceGroup>
   ```

   ![image](https://github.com/user-attachments/assets/8a512b7c-85c5-4ab1-a173-4ba68c1863e1)

6. Fire-up a Python3 Web Server and navigate to the newly generated "azure_resource_graph.HTML" file

   [image]

