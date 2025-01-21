import subprocess
import json
import networkx as nx
from pyvis.network import Network
from concurrent.futures import ThreadPoolExecutor

# Function to run az CLI commands and return JSON output
def run_az_cli(command):
    print(f"Running command: {command}")  # Added print for command execution
    result = subprocess.run(command, shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error executing command: {result.stderr}")
        return None
    return json.loads(result.stdout)

# Helper function to fetch role assignments at various scopes
def fetch_role_assignments(resource_id, resource_group_id, subscription_id, processed_scopes):
    print(f"Fetching role assignments for resource: {resource_id}")  # Output
    scopes = [
        resource_id,  # Resource scope
        resource_group_id,  # Resource Group scope
        f"/subscriptions/{subscription_id}"  # Subscription scope
    ]
    
    role_assignments = []
    
    # Process only if not already processed for this scope
    for scope in scopes:
        if scope not in processed_scopes:
            print(f"Fetching role assignments for scope: {scope}")
            command = f"az role assignment list --scope {scope} --subscription {subscription_id} --output json"
            assignments = run_az_cli(command)
            if assignments:
                role_assignments.extend(assignments)
            processed_scopes.add(scope)  # Mark scope as processed
    print(f"Found {len(role_assignments)} role assignments for {resource_id}")  # Output
    return role_assignments

# Function to fetch Key Vault Access Policies and update the graph
def add_keyvault_access_policies(resource_id, subscription_id):
    # Extract the Key Vault name and resource group from the resource ID
    parts = resource_id.split('/')
    resource_group_name = parts[4]  # Extract resource group name (5th segment)
    keyvault_name = parts[-1]  # Extract Key Vault name (last segment)

    print(f"Fetching access policies for Key Vault: {keyvault_name}")  # Output
    # Construct the command with --name and --resource-group
    command = f"az keyvault show --name {keyvault_name} --resource-group {resource_group_name} --subscription {subscription_id} --query properties.accessPolicies -o json"
    
    # Run the command and capture access policies
    access_policies = run_az_cli(command)

    # Debug: Print the output from Azure CLI to verify the access policies
    print("Access Policies Retrieved:")
    print(access_policies)

    if not access_policies:
        print(f"No access policies found for Key Vault: {resource_id}")
        return

    print(f"Found {len(access_policies)} access policies for {keyvault_name}")  # Output

    # Ensure Key Vault node exists in the graph
    if not G.has_node(resource_id):
        G.add_node(resource_id, label=keyvault_name, type="KeyVault")
        print(f"Added KeyVault node: {keyvault_name} ({resource_id})")  # Debugging

    # Loop through the access policies and add the corresponding edges
    for policy in access_policies:
        principal_id = policy.get("objectId", "Unknown")
        permissions = policy.get("permissions", {})
        secrets_permissions = permissions.get("secrets", [])
        keys_permissions = permissions.get("keys", [])
        certificates_permissions = permissions.get("certificates", [])

        # Check if the principal has any permissions
        if not (secrets_permissions or keys_permissions or certificates_permissions):
            continue  # Skip if no permissions exist for this identity
        
        permission_details = []
        if secrets_permissions:
            permission_details.append(("Secret", secrets_permissions))
        if keys_permissions:
            permission_details.append(("Key", keys_permissions))
        if certificates_permissions:
            permission_details.append(("Certificate", certificates_permissions))

        # Add an edge for each permission type
        for perm_type, perm_list in permission_details:
            principal_label = principal_upns.get(principal_id, principal_id)

            # Ensure principal node exists
            if not G.has_node(principal_id):
                G.add_node(principal_id, label=principal_label, type="User/Principal", color=get_identity_color("User"))
                print(f"Added principal node: {principal_label} ({principal_id})")  # Debugging

            # Create the edge between the identity and the Key Vault for each permission type
            permission_actions = ', '.join(perm_list)  # Join the list of permissions into a comma-separated string
            edge_label = f"{perm_type}: {permission_actions}"

            for _ in perm_list:  # Multiple actions (e.g., Get, List) can be present, but we only care about the type
                if not G.has_edge(principal_id, resource_id, key=edge_label):
                    print(f"Adding edge: {principal_id} -> {resource_id} with label {edge_label}")  # Debugging
                    G.add_edge(principal_id, resource_id, label=edge_label, key=edge_label)  # Adding with key

# Function to get a dictionary mapping subscription IDs to subscription names
def get_subscription_id_name_map():
    print("Fetching subscription list...")  # Output
    command = "az account list --query '[].{id:id, name:name}' -o json"
    subscriptions = run_az_cli(command)
    if subscriptions:
        print(f"Found {len(subscriptions)} subscriptions.")  # Output
        return {sub["id"]: sub["name"] for sub in subscriptions}
    print("No subscriptions found.")
    return {}

# Fetch all UPNs or display names for all principal IDs in the tenant
def fetch_all_principals_upns():
    print("Fetching UPNs for all principals...")  # Output
    # Query Azure AD for all users and service principals (expand this as needed)
    users_command = "az ad user list --query '[].{id:id, upn:userPrincipalName}' -o json"
    sp_command = "az ad sp list --query '[].{id:id, displayName:displayName}' -o json"
    
    users = run_az_cli(users_command)
    service_principals = run_az_cli(sp_command)
    
    principal_upns = {}

    # Add users to the map
    if users:
        for user in users:
            principal_upns[user["id"]] = user["upn"]

    # Add service principals to the map
    if service_principals:
        for sp in service_principals:
            principal_upns[sp["id"]] = sp["displayName"]
    
    return principal_upns

# Function to assign color based on identity type
def get_identity_color(principal_type):
    colors = {
        "User": "#08cc27",
        "ServicePrincipal": "#b035e5",
        "Application": "#2E8B57",
        "ManagedIdentity": "#FCD117"
    }
    return colors.get(principal_type, "gray")

# Assign colors for Subscription and Resource Group nodes
def get_special_node_color(node_type):
    if node_type == "Subscription":
        return "#f0d511"
    elif node_type == "ResourceGroup":
        return "#4682B4"
    return "#FF8C00"

# Get all subscriptions (ID and Name mapping)
subscription_id_name_map = get_subscription_id_name_map()
subscription_ids = list(subscription_id_name_map.keys())

if not subscription_ids:
    print("No subscriptions found. Exiting.")
    exit(1)

# Fetch all principal UPNs or display names
principal_upns = fetch_all_principals_upns()

# Step 1: Fetch resources (VMs, Storage Accounts, Key Vaults, etc.)
resource_types = [
    "Microsoft.Compute/virtualMachines",
    "Microsoft.Storage/storageAccounts",
    "Microsoft.KeyVault/vaults",
    "Microsoft.ManagedIdentity/userAssignedIdentities"
]

# Use MultiDiGraph to allow multiple edges
G = nx.MultiDiGraph()

# Function to process each subscription
def process_subscription(subscription_id):
    print(f"Processing Subscription: {subscription_id}")
    subscription_name = subscription_id_name_map.get(subscription_id, f"Subscription {subscription_id}")
    
    # Set to track processed resource group and subscription scopes
    processed_scopes = set()

    resources = []
    for resource_type in resource_types:
        print(f"Fetching resources of type: {resource_type} for subscription: {subscription_id}")  # Output
        command = f"az resource list --resource-type {resource_type} --subscription {subscription_id} --output json"
        resource_data = run_az_cli(command)
        if resource_data:
            resources += resource_data

    print(f"Found {len(resources)} resources in subscription: {subscription_id}")  # Output
    for resource in resources:
        # Extract details of the resource
        resource_id = resource["id"]
        resource_name = resource["name"]
        resource_type = resource["type"]
        resource_group_id = "/".join(resource_id.split("/")[:5])  # Extract resource group ID

        print(f"Processing resource: {resource_name} ({resource_type})")  # Log resource being processed

        # Add the resource to the graph
        G.add_node(resource_id, label=resource_name, type=resource_type)

        # Add Resource Group node if it doesn't exist
        if not G.has_node(resource_group_id):
            resource_group_name = resource["id"].split("/")[4]
            G.add_node(resource_group_id, label=resource_group_name, type="ResourceGroup")

        # Add Subscription node if it doesn't exist
        subscription_node = f"/subscriptions/{subscription_id}"
        if not G.has_node(subscription_node):
            subscription_name = subscription_id_name_map.get(subscription_id, f"Subscription {subscription_id}")
            G.add_node(subscription_node, label=subscription_name, type="Subscription")

        # Add edges for resource hierarchy
        G.add_edge(resource_group_id, resource_id, label="Contains")
        G.add_edge(subscription_node, resource_group_id, label="Contains")

        # **Add the Managed Identity-specific logic here:**
        if resource_type == "Microsoft.ManagedIdentity/userAssignedIdentities":
            print(f"Adding Managed Identity to the graph: {resource_name} (ID: {resource_id})")

        # Process Key Vault Access Policies (if resource is Key Vault)
        if resource_type == "Microsoft.KeyVault/vaults":
            add_keyvault_access_policies(resource_id, subscription_id)

        # Fetch role assignments only once per resource group and subscription
        role_assignments = fetch_role_assignments(resource_id, resource_group_id, subscription_id, processed_scopes)

        for role in role_assignments:
            principal_id = role.get("principalId", "Unknown")
            principal_type = role.get("principalType", "Unknown")
            role_name = role.get("roleDefinitionName", "Unknown")

            principal_label = principal_upns.get(principal_id, principal_id)  # Use cached UPN

            if not G.has_node(principal_id):
                G.add_node(principal_id, label=principal_label, type=principal_type, color=get_identity_color(principal_type))

            # Ensure the role is attached to the correct scope
            if resource_id in role["scope"]:
                G.add_edge(principal_id, resource_id, label=role_name)  # Resource level permissions
            elif resource_group_id in role["scope"]:
                G.add_edge(principal_id, resource_group_id, label=role_name)  # Resource Group level permissions
            elif f"/subscriptions/{subscription_id}" in role["scope"]:
                G.add_edge(principal_id, subscription_node, label=role_name)  # Subscription level permissions

# Use ThreadPoolExecutor to process subscriptions in parallel
with ThreadPoolExecutor() as executor:
    executor.map(process_subscription, subscription_ids)

# Step 3: Create an interactive graph using Pyvis
net = Network(height="750px", width="100%", directed=True)

# Add nodes and edges to Pyvis graph
for node, data in G.nodes(data=True):
    label = data.get("label", node)
    color = data.get("color", get_special_node_color(data.get("type", "Unknown")))
    net.add_node(node, label=label, title=data.get("type", "Unknown"), color=color)

for source, target, data in G.edges(data=True):
    role = data.get("label", "Unknown")  # Use the label as the edge's permission name
    net.add_edge(source, target, title=role, label=role)

# Customizing graph options to enable search functionality
net.set_options("""
var options = {
  "nodes": {
    "shape": "dot",
    "size": 16
  },
  "edges": {
    "arrows": {
      "to": { "enabled": true, "scaleFactor": 1.5 }
    }
  },
  "physics": {
    "barnesHut": {
      "gravitationalConstant": -80000,
      "springLength": 250
    }
  },
  "manipulation": {
    "enabled": true
  },
  "interaction": {
    "navigationButtons": true,
    "zoomView": true
  }
}
""")

# Add the search functionality to the graph
search_html = """
<script type="text/javascript">
  window.onload = function() {
    // Create a search input field for the graph search
    var searchInput = document.createElement('input');
    searchInput.setAttribute('type', 'text');
    searchInput.setAttribute('placeholder', 'Search for a resource or role...');
    searchInput.setAttribute('id', 'searchBox');
    searchInput.style.position = 'absolute';
    searchInput.style.top = '10px';
    searchInput.style.left = '50%';
    searchInput.style.transform = 'translateX(-50%)';
    searchInput.style.zIndex = '10';  // Ensure it's above other elements
    document.body.appendChild(searchInput);

    // Create a dropdown for filtering by category (e.g., Resource Types)
    var categoryDropdown = document.createElement('select');
    categoryDropdown.setAttribute('id', 'categoryDropdown');
    categoryDropdown.style.position = 'absolute';
    categoryDropdown.style.top = '50px';
    categoryDropdown.style.left = '50%';
    categoryDropdown.style.transform = 'translateX(-50%)';
    categoryDropdown.style.zIndex = '10';
    document.body.appendChild(categoryDropdown);

    var categories = ["All", "Microsoft.Compute/virtualMachines", "Microsoft.Storage/storageAccounts", "Microsoft.KeyVault/vaults", "Microsoft.ManagedIdentity/userAssignedIdentities"];
    categories.forEach(function(category) {
      var option = document.createElement('option');
      option.value = category;
      option.text = category.split('/').pop();
      categoryDropdown.appendChild(option);
    });

    // Function to filter nodes and edges
    function filterGraph() {
      var searchQuery = searchInput.value.toLowerCase();
      var selectedCategory = categoryDropdown.value;
      var visibleNodes = new Set();
      var visibleEdges = [];

      // Filter nodes based on the search query and selected category
      network.body.data.nodes.get().forEach(function(node) {
        var nodeLabel = node.label.toLowerCase();
        var nodeType = node.title;
        var isCategoryMatch = selectedCategory === "All" || nodeType === selectedCategory;
        var isSearchMatch = nodeLabel.includes(searchQuery) || searchQuery === "";

        if (isSearchMatch && isCategoryMatch) {
          visibleNodes.add(node.id);
        }
      });

      // Filter edges that are connected to visible nodes
      network.body.data.edges.get().forEach(function(edge) {
        if (visibleNodes.has(edge.from) || visibleNodes.has(edge.to)) {
          visibleEdges.push(edge);
          visibleNodes.add(edge.from);
          visibleNodes.add(edge.to);
        }
      });

      // Update the graph to show only visible nodes and edges
      network.body.data.nodes.forEach(function(node) {
        if (visibleNodes.has(node.id)) {
          network.body.data.nodes.update({ id: node.id, hidden: false });
        } else {
          network.body.data.nodes.update({ id: node.id, hidden: true });
        }
      });

      network.body.data.edges.forEach(function(edge) {
        if (visibleEdges.includes(edge)) {
          network.body.data.edges.update({ id: edge.id, hidden: false });
        } else {
          network.body.data.edges.update({ id: edge.id, hidden: true });
        }
      });
    }

    // Add event listeners to search input and category dropdown
    searchInput.addEventListener('input', filterGraph);
    categoryDropdown.addEventListener('change', filterGraph);
  };
</script>
"""

# Save the interactive graph to an HTML file
net.save_graph("azure_resource_graph.html")

# Append the search functionality HTML to the generated HTML file
with open("azure_resource_graph.html", "a") as f:
    f.write(search_html)

print("Graph saved as 'azure_resource_graph.html'")
