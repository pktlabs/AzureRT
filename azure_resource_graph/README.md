A.R.G. - azure_resource_graph.py
> [!NOTE]
> - Compatible with Python 3.12+
> - Sheds light on Azurehound blindspots
> - `az cli` wrapper 🌯
> - Inspired by @andyrobbins work on [AzureHound](https://github.com/SpecterOps/AzureHound)

> [!WARNING]
> 🏗️ WIP 🏗️
> - [x] Fix the "Search and Category" filters >.>
> - [x] Remove duplicate edges
> - [ ] Make nodes "movable" as opposed to fluid
> - [x] Add all Resource Groups and map Access Control to Identities
> - [x] Add all Subscriptions and map Access Control to Identities
> - [x] Show Custom Azure RBAC Role assigned to Managed Identities

---

## Overview  
The `azure_resource_graph.py` script is designed to build a graph-view through Node-Edge relationships across multiple Azure resources to help shed light on potential blindspots, such as Storage Account access control, visualized with `Sigma.js`.

## Prerequisites  
To use this script, you need the following:

- **az cli**: Authenticate with `az login` before launching `azure_resource_graph.py`.
- **Azure RBAC Reader**: The identity to use with the `az cli` requires atleast "Reader" on the subscriptions in-scope.

## Usage

   ```bash
   # 1. Clone or download this repository. 
   git clone https://github.com/fjodoin/AzureRT.git

   # 2. Change into the according directory.
   cd ./AzureRT/azure_resource_graph
   ```

   ![image](https://github.com/user-attachments/assets/733e9ce5-c2c9-4884-8031-3ac87c2f0976)

   
   ```bash
   # 3. Run the script (ensure that you are already authenticated with the az cli through "az login")
   python3 azure_resource_graph.py
   ```

   [image]


   ```bash
   # 4. Fire-up npm to host the Web App and navigate to http://127.0.0.1:3000
   npm run start

   # 5. Upload the output_azure_resource_data.json
   ```

   ![image](https://github.com/user-attachments/assets/23f2adc5-5542-4317-b685-547ae4732758)







   

