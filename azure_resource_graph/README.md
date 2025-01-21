# A.R.G. - azure_resource_graph.py
> [!NOTE]
> - Compatible with Python 3.12+
> - Sheds light on Azurehound blindspots
> - `az cli` wrapper 🌯
> - Inspired by @andyrobbins work on [AzureHound](https://github.com/SpecterOps/AzureHound)

---

## Overview  
The `azure_resource_graph.py` script is designed build a graph-view of Node-Edge relationships across multiple Azure resources to help shed light on potential blindspots, such as Azure Key Vault "Access Policies", and Storage Account Access Control.  

## Prerequisites  
To use this script, you need the following:

- **az cli**: Authenticate with `az login` before launching `azure_resource_graph.py`.

## Usage

   ```bash
   # 1. Clone or download this repository. 
   git clone https://github.com/fjodoin/AzureRT.git

   # 2. Change into the according directory.
   cd ./AzureRT/azure_resource_graph

   # 3. Fire-up a Python3 virtual environment
   python3 -m venv arg_venv ; source arg_venv/bin/activate # You may have to install Python3 Virtual Environments with "sudo apt install python3.12-venv"

   # 4. Install all the dependies
   python3 -m pip install -r requirements.txt
   ```

   ![image](https://github.com/user-attachments/assets/2207a6cb-120e-4e95-818f-424b0b734f5a)



   
   ```bash
   # 5. Run the script (ensure that you are already authenticate with the az cli through "az login")
   python3 azure_resource_graph.py
   ```

   ![image](https://github.com/user-attachments/assets/6d83d836-3c1e-402f-a868-37ea1a24d6bc)


   ```bash
   # 6. Fire-up a Python3 Web Server and navigate to the newly generated "azure_resource_graph.HTML" file
   python3 -m http.server 1337

   # 7. Navigate to http://127.0.0.1:1337/azure_resource_graph.html in your favorite browser
   ```

   ![image](https://github.com/user-attachments/assets/5468a0eb-8e12-425a-83f4-59bc158f4fb2)




   

