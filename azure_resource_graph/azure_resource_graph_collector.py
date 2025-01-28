import json
import subprocess
from concurrent.futures import ThreadPoolExecutor
from typing import List, Dict, Set, Tuple

# Constants
RESOURCE_TYPES = [
    "Microsoft.Compute/virtualMachines",
    "Microsoft.Compute/virtualMachineScaleSets",
    "Microsoft.Storage/storageAccounts",
    "Microsoft.KeyVault/vaults",
    "Microsoft.Web/sites",
    "Microsoft.ManagedIdentity/userAssignedIdentities",
    "Microsoft.ContainerService/managedClusters",
    "Microsoft.Automation/automationAccounts"
]

RESOURCE_COLORS = {
    "Microsoft.Compute/virtualMachines": "#1f77b4",
    "Microsoft.Compute/virtualMachineScaleSets": "#aec7e8",
    "Microsoft.Storage/storageAccounts": "#2ca02c",
    "Microsoft.KeyVault/vaults": "#9467bd",
    "Microsoft.Web/sites": "#e377c2",
    "Microsoft.ManagedIdentity/userAssignedIdentities": "#ff7f0e",
    "Microsoft.ContainerService/managedClusters": "#17becf",
    "Microsoft.Automation/automationAccounts": "#8c564b",
    "ResourceGroup": "#7f7f7f",
    "Subscription": "#bcbd22",
    "SystemAssignedManagedIdentity": "#98df8a",
    "Principal": "#d62728",
    "FederatedCredential": "#9edae5"
}

principal_name_cache = {}

class AzureResourceGraph:
    def __init__(self):
        self.nodes = []
        self.node_ids = set()
        self.edges = []
        self.edge_tuples = set()

    def add_node(self, node_id: str, name: str, node_type: str, color: str = None):
        existing_node = next((node for node in self.nodes if node["id"] == node_id), None)
        if existing_node:
            # Merge nodes, favoring UserAssignedManagedIdentity
            if node_type == "UserAssignedManagedIdentity":
                existing_node.update({"label": name, "type": node_type, "color": RESOURCE_COLORS[node_type]})
        else:
            color = color or RESOURCE_COLORS.get(node_type, "blue")
            self.nodes.append({
                "id": node_id,
                "label": name,
                "type": node_type,
                "resourceType": node_type,
                "color": color
            })
        self.node_ids.add(node_id)


    def add_edge(self, source: str, target: str, label: str, color: str = "black"):
        edge_key = (source, target, label, color)  # Include color in the uniqueness check
        if edge_key not in self.edge_tuples:
            self.edges.append({
                "source": source,
                "target": target,
                "label": label,
                "color": color
            })
            self.edge_tuples.add(edge_key)

    def write_to_file(self, filename: str = "output_azure_resource_data.json"):
        data = {"nodes": self.nodes, "edges": self.edges}
        with open(filename, "w") as file:
            json.dump(data, file, indent=2)
        print(f"Data written to {filename}")

class AzureCLI:
    @staticmethod
    def run_az_cli(command: str) -> List[Dict]:
        try:
            print("[*]", command)
            result = subprocess.run(command, shell=True, capture_output=True, text=True)
            return json.loads(result.stdout) if result.returncode == 0 else []
        except Exception as e:
            print(f"Exception while running command: {e}")
            return []

class AzureResourceProcessor:
    def __init__(self, graph: AzureResourceGraph, cli: AzureCLI):
        self.graph = graph
        self.cli = cli

    def get_principal_names(self, principal_ids: List[str]) -> Dict[str, str]:
        global principal_name_cache
        uncached_ids = [pid for pid in principal_ids if pid not in principal_name_cache]
        if uncached_ids:
            quoted_ids = ",".join([f"'{pid}'" for pid in uncached_ids])
            user_command = f"az ad user list --filter \"id in ({quoted_ids})\" --query '[].{{id:id, name:displayName}}' --output json"
            sp_command = f"az ad sp list --filter \"id in ({quoted_ids})\" --query '[].{{id:id, name:displayName}}' --output json"

            user_data = self.cli.run_az_cli(user_command)
            sp_data = self.cli.run_az_cli(sp_command)

            for record in user_data + sp_data:
                principal_name_cache[record['id']] = record['name']

            for pid in uncached_ids:
                principal_name_cache.setdefault(pid, pid)

        return {pid: principal_name_cache[pid] for pid in principal_ids}

    def fetch_role_assignments(self, resource_id: str, resource_group_id: str, subscription_id: str, processed_scopes: Set[str]) -> Dict[str, Tuple[str, str, str]]:
        scopes = [f"/subscriptions/{subscription_id}", resource_group_id, resource_id]
        role_assignments = {}

        for scope in scopes:
            if scope not in processed_scopes:
                command = f"az role assignment list --scope {scope} --subscription {subscription_id} --output json"
                assignments = self.cli.run_az_cli(command)
                for role in assignments:
                    principal_id = role.get("principalId", "Unknown")
                    role_name = role.get("roleDefinitionName", "Unknown")
                    role_assignments[principal_id] = (scope, role_name)
                processed_scopes.add(scope)

        principal_ids = list(role_assignments.keys())
        principal_names = self.get_principal_names(principal_ids)

        return {pid: (data[0], data[1], principal_names[pid]) for pid, data in role_assignments.items()}

    def fetch_keyvault_access_policies(self, keyvault_id: str, subscription_id: str) -> List[Tuple[str, str, List[str]]]:
        """
        Fetch and process Key Vault access policies.
        Returns a list of (principal_id, permission_type, permissions) where permissions is non-empty.
        """
        keyvault_name = keyvault_id.split("/")[-1]
        resource_group = keyvault_id.split("/")[4]

        command = (
            f"az keyvault show --name {keyvault_name} --resource-group {resource_group} "
            f"--query 'properties.accessPolicies' --output json --subscription {subscription_id}"
        )
        access_policies = self.cli.run_az_cli(command)
        if not access_policies:
            return []

        # Flatten the access policies
        flattened_policies = []
        for policy in access_policies:
            principal_id = policy.get("objectId")
            permissions = policy.get("permissions", {})
            if principal_id:
                for permission_type in ["keys", "secrets", "certificates"]:
                    if permissions.get(permission_type):  # Only include non-empty permissions
                        flattened_policies.append((principal_id, permission_type, permissions[permission_type]))

        return flattened_policies

    def fetch_federated_credentials(self, identity_id: str, subscription_id: str) -> List[Dict]:
        """
        Fetch federated credentials for a managed identity.
        """
        # Extract resource group and identity name from the identity_id
        parts = identity_id.split("/")
        resource_group = parts[4]  # Resource group is the 5th part of the ID
        identity_name = parts[-1]  # Identity name is the last part of the ID

        # Construct the command with resource group and identity name
        command = (
            f"az identity federated-credential list "
            f"--resource-group {resource_group} "
            f"--identity-name {identity_name} "
            f"--subscription {subscription_id} "
            f"--output json"
        )
        federated_credentials = self.cli.run_az_cli(command)
        return federated_credentials if federated_credentials else []

    def process_subscription(self, subscription_id: str, subscription_name: str, resource_types: List[str]):
        processed_scopes = set()
        command = f"az resource list --subscription {subscription_id} --output json"
        resources = self.cli.run_az_cli(command)

        resources = [res for res in resources if res["type"] in resource_types]
        for resource in resources:
            resource_id = resource["id"]
            resource_name = resource["name"]
            resource_type = resource["type"]
            resource_group_id = "/".join(resource_id.split("/")[:5])

            self.graph.add_node(resource_id, resource_name, resource_type)
            self.graph.add_node(resource_group_id, resource_group_id.split("/")[-1], "ResourceGroup")
            self.graph.add_node(f"/subscriptions/{subscription_id}", subscription_name, "Subscription")

            self.graph.add_edge(f"/subscriptions/{subscription_id}", resource_group_id, "Contains", color="gold")
            self.graph.add_edge(resource_group_id, resource_id, "Contains", color="orange")

            if resource.get("identity") and resource["identity"].get("type") == "SystemAssigned":
                principal_id = resource["identity"]["principalId"]
                self.graph.add_node(principal_id, f"{resource_name}-Identity", "SystemAssignedManagedIdentity")
                self.graph.add_edge(principal_id, resource_id, "SystemAssignedIdentity", color="green")

            highest_scope_roles = self.fetch_role_assignments(resource_id, resource_group_id, subscription_id, processed_scopes)
            for principal_id, (scope, role_name, principal_name) in highest_scope_roles.items():
                self.graph.add_node(principal_id, principal_name, "Principal")
                self.graph.add_edge(principal_id, scope, role_name, color="green")

            # Process Key Vault access policies
            if resource_type == "Microsoft.KeyVault/vaults":
                access_policies = self.fetch_keyvault_access_policies(resource_id, subscription_id)
                for principal_id, permission_type, permissions in access_policies:
                    if permissions:  # Ensure there are permissions for this access type
                        principal_name = self.get_principal_names([principal_id]).get(principal_id, principal_id)
                        self.graph.add_node(principal_id, principal_name, "Principal")
                        self.graph.add_edge(principal_id, resource_id, f"Access: {permission_type.capitalize()}", color="purple")

            # Check if the resource is a managed identity and has federated credentials
            if resource_type == "Microsoft.ManagedIdentity/userAssignedIdentities":
                federated_credentials = self.fetch_federated_credentials(resource_id, subscription_id)
                if federated_credentials:
                    for cred in federated_credentials:
                        cred_id = cred.get("id", "Unknown")
                        cred_name = cred.get("name", "Unknown")
                        self.graph.add_node(cred_id, cred_name, "FederatedCredential")
                        self.graph.add_edge(resource_id, cred_id, "HasFederatedCredential", color="blue")


    def process_all_subscriptions(self, resource_types: List[str]):
        subscriptions = self.cli.run_az_cli("az account list --output json")
        if not subscriptions:
            print("No subscriptions found.")
            return

        with ThreadPoolExecutor() as executor:
            futures = [
                executor.submit(self.process_subscription, subscription["id"], subscription["name"], resource_types)
                for subscription in subscriptions
            ]
            for future in futures:
                future.result()

# Main Execution
if __name__ == "__main__":
    graph = AzureResourceGraph()
    cli = AzureCLI()
    processor = AzureResourceProcessor(graph, cli)

    processor.process_all_subscriptions(RESOURCE_TYPES)
    graph.write_to_file()
