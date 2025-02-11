import json
import subprocess
from concurrent.futures import ThreadPoolExecutor
from typing import List, Dict

# The color palette (unchanged)
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
    "UserAssignedManagedIdentity": "#ff7f0e",
    "Principal": "#d62728",
    "FederatedCredential": "#9edae5"
}

##############################################################################
#                           HELPER: Chunking IDs
##############################################################################
def chunk_list(lst, chunk_size=7):
    """
    Yield successive chunks of size 'chunk_size' from the list 'lst'.
    """
    for i in range(0, len(lst), chunk_size):
        yield lst[i : i + chunk_size]


class AzureCLI:
    @staticmethod
    def run_az_cli(command: str):
        """
        Runs a shell command with Azure CLI and returns the parsed JSON or raw string.
        If an error occurs or the command exits with a non-zero code, returns an empty list.
        """
        try:
            result = subprocess.run(command, shell=True, capture_output=True, text=True)
            if result.returncode != 0:
                print(f"[ERROR] Command failed ({result.returncode}): {command}\n{result.stderr}")
                return []
            # Try to parse JSON
            try:
                return json.loads(result.stdout)
            except json.JSONDecodeError:
                # If not valid JSON, just return the raw string
                return result.stdout
        except Exception as e:
            print(f"Exception while running command: {e}")
            return []


class AzureResourceGraph:
    def __init__(self):
        self.nodes = []
        self.edges = []
        self.node_set = set()  # To deduplicate nodes by ID
        self.edge_set = set()  # To deduplicate edges by (source, target, label)

    def add_node(self, node_id, name, node_type, color=None):
        if node_id not in self.node_set:
            self.node_set.add(node_id)
            color = color or RESOURCE_COLORS.get(node_type, "#1f77b4")
            self.nodes.append({
                "id": node_id,
                "label": name,
                "type": node_type,
                "color": color
            })

    def add_edge(self, source, target, label, color="black"):
        edge_key = (source, target, label)
        if edge_key not in self.edge_set:
            self.edge_set.add(edge_key)
            self.edges.append({
                "source": source,
                "target": target,
                "label": label,
                "color": color
            })

    def write_to_file(self, filename="output_azure_resource_data.json"):
        data = {"nodes": self.nodes, "edges": self.edges}
        with open(filename, "w") as file:
            json.dump(data, file, indent=2)
        print(f"[INFO] Data written to {filename}")


class AzureResourceProcessor:
    def __init__(self, graph: AzureResourceGraph, cli: AzureCLI):
        self.graph = graph
        self.cli = cli
        # principalId -> displayName or fallback
        self.principal_name_cache = {}

    #########################################################################
    #                          PRINCIPAL NAME LOOKUP
    #########################################################################
    def get_principal_name_single(self, pid: str) -> str:
        """
        Resolves a single principal's displayName, checking in this order:
          1) az ad user show --id
          2) az ad sp show --id
          3) az ad group show --group
        If all fail, fallback to the principalId itself.
        """
        # 1) Try user
        cmd_user = f"az ad user show --id {pid} --query displayName --output tsv"
        result_user = self.cli.run_az_cli(cmd_user)
        if isinstance(result_user, str) and result_user.strip():
            return result_user.strip()

        # 2) Try service principal
        cmd_sp = f"az ad sp show --id {pid} --query displayName --output tsv"
        result_sp = self.cli.run_az_cli(cmd_sp)
        if isinstance(result_sp, str) and result_sp.strip():
            return result_sp.strip()

        # 3) Try group
        cmd_group = f"az ad group show --group {pid} --query displayName --output tsv"
        result_group = self.cli.run_az_cli(cmd_group)
        if isinstance(result_group, str) and result_group.strip():
            return result_group.strip()

        # fallback
        return pid

    def get_principal_names(self, principal_ids: List[str]) -> Dict[str, str]:
        """
        For each principalId, return a dict of {id: displayName}.
        We'll do them one-by-one (simple approach).
        """
        to_resolve = [p for p in principal_ids if p not in self.principal_name_cache]
        for p_id in to_resolve:
            name = self.get_principal_name_single(p_id)
            self.principal_name_cache[p_id] = name

        # Now return a map of all
        return {p: self.principal_name_cache.get(p, p) for p in principal_ids}

    #########################################################################
    #                         KEY VAULT ACCESS POLICIES
    #########################################################################
    def fetch_key_vault_access_policies(self, vault_id: str) -> List[Dict]:
        parts = vault_id.split("/")
        resource_group = parts[4]
        vault_name = parts[-1]
        subscription_id = parts[2]
        print(f"[DEBUG] Fetching Key Vault access policies for {vault_name} in {resource_group}...")
        command = (
            f"az keyvault show "
            f"--resource-group {resource_group} "
            f"--name {vault_name} "
            f"--subscription {subscription_id} "
            f"--query 'properties.accessPolicies' "
            f"--output json"
        )
        access_policies = self.cli.run_az_cli(command)
        return access_policies if isinstance(access_policies, list) else []

    def process_key_vault_access_policies(self, vault_id: str):
        policies = self.fetch_key_vault_access_policies(vault_id)
        if not policies:
            return
        principal_to_permissions = {}
        for policy in policies:
            principal_id = policy.get("objectId")
            if not principal_id:
                continue
            perms = policy.get("permissions", {})
            categories = set()
            if perms.get("secrets"):
                categories.add("Secrets")
            if perms.get("keys"):
                categories.add("Keys")
            if perms.get("certificates"):
                categories.add("Certificates")
            if principal_id not in principal_to_permissions:
                principal_to_permissions[principal_id] = set()
            principal_to_permissions[principal_id].update(categories)
        if not principal_to_permissions:
            return
        principal_ids = list(principal_to_permissions.keys())
        pid_to_name = self.get_principal_names(principal_ids)
        print(f"[DEBUG] Creating Key Vault edges for {len(principal_ids)} principals on vault {vault_id}...")
        for pid, cat_set in principal_to_permissions.items():
            principal_label = pid_to_name[pid]
            self.graph.add_node(pid, principal_label, "Principal", RESOURCE_COLORS.get("Principal"))
            for cat in cat_set:
                self.graph.add_edge(pid, vault_id, cat, color="#9edae5")

    #########################################################################
    #                         ROLE ASSIGNMENTS (RBAC)
    #########################################################################
    def fetch_role_assignments(self, scope: str) -> List[Dict]:
        print(f"[DEBUG] Fetching role assignments for scope: {scope} ...")
        command = (
            f"az role assignment list "
            f"--scope \"{scope}\" "
            f"--output json"
        )
        output = self.cli.run_az_cli(command)
        return output if isinstance(output, list) else []

    def process_iam_for_scope(self, scope_id: str):
        assignments = self.fetch_role_assignments(scope_id)
        if not assignments:
            print(f"[DEBUG] No role assignments found for scope: {scope_id}")
            return
        principal_roles_map = {}
        for a in assignments:
            pid = a.get("principalId")
            role_name = a.get("roleDefinitionName")
            if not pid or not role_name:
                continue
            if pid not in principal_roles_map:
                principal_roles_map[pid] = set()
            principal_roles_map[pid].add(role_name)
        principal_ids = list(principal_roles_map.keys())
        pid_to_name = self.get_principal_names(principal_ids)
        print(f"[DEBUG] Creating IAM edges for {len(principal_ids)} principals at {scope_id}...")
        for pid, roles in principal_roles_map.items():
            display_name = pid_to_name[pid]
            self.graph.add_node(pid, display_name, "Principal", RESOURCE_COLORS.get("Principal"))
            for role_name in roles:
                self.graph.add_edge(pid, scope_id, role_name, color="#d62728")

    #########################################################################
    #  FETCH FEDERATED CREDENTIALS FOR A UAMI
    #########################################################################
    def fetch_federated_credentials_for_uami(self, uami_id: str):
        """
        For a given UAMI resourceId, call:
          az identity federated-credential list --identity-name <uamiName> --resource-group <rg> --subscription <sub>
        Returns list of {name, issuer, subject, etc.}
        """
        # Example resource ID:
        # /subscriptions/xxxxxx/resourceGroups/rg-name/providers/Microsoft.ManagedIdentity/userAssignedIdentities/uamiName
        parts = uami_id.split("/")
        subscription_id = parts[2]
        rg_name = parts[4]
        identity_name = parts[-1]

        cmd = (
            f"az identity federated-credential list "
            f"--identity-name {identity_name} "
            f"--resource-group {rg_name} "
            f"--subscription {subscription_id} "
            f"--output json"
        )
        print(f"[DEBUG] Running: {cmd}")
        result = self.cli.run_az_cli(cmd)
        if isinstance(result, list):
            return result
        return []

    #########################################################################
    #  NEW: EXPLICITLY PROCESS UAMI RESOURCE
    #########################################################################
    def process_uami_resource(self, resource: dict):
        """
        Processes a "Microsoft.ManagedIdentity/userAssignedIdentities" resource.
        Because it does not have 'resource["identity"]', we fetch federated creds directly.
        """
        uami_id = resource["id"]
        uami_name = resource["name"]
        # Add the UAMI node
        self.graph.add_node(
            uami_id,
            uami_name,
            "UserAssignedManagedIdentity",
            color=RESOURCE_COLORS.get("UserAssignedManagedIdentity")
        )

        # Fetch Federated Credentials
        fed_creds = self.fetch_federated_credentials_for_uami(uami_id)
        for fc in fed_creds:
            fc_name = fc.get("name", "unknownFederatedCred")
            fc_id = f"{uami_id}/federatedCredentials/{fc_name}"
            self.graph.add_node(
                fc_id,
                fc_name,
                "FederatedCredential",
                color=RESOURCE_COLORS.get("FederatedCredential")
            )
            self.graph.add_edge(uami_id, fc_id, "Federated Credentials", color="#9edae5")

        # Optionally fetch principalId from 'az identity show' for a direct link
        cmd = f"az identity show --ids \"{uami_id}\" --query principalId --output tsv"
        principal_id = self.cli.run_az_cli(cmd)
        if isinstance(principal_id, str) and principal_id.strip():
            principal_id = principal_id.strip()
            pid_to_name = self.get_principal_names([principal_id])
            principal_display_name = pid_to_name[principal_id]
            self.graph.add_node(
                principal_id,
                principal_display_name,
                "Principal",
                color=RESOURCE_COLORS.get("Principal")
            )
            self.graph.add_edge(uami_id, principal_id, "Linked", color="blue")

    #########################################################################
    #  PROCESS MANAGED IDENTITIES ON OTHER RESOURCES
    #########################################################################
    def process_resource_identities(self, resource: dict):
        resource_id = resource["id"]
        identity_data = resource.get("identity")
        if not identity_data:
            return  # For normal resources that do not have an identity block.

        identity_type = identity_data.get("type", "")
        # If resource has SystemAssigned identity
        if "SystemAssigned" in identity_type:
            sys_assigned_principal_id = identity_data.get("principalId")
            if sys_assigned_principal_id:
                sami_node_id = f"{resource_id}/systemAssignedIdentity"
                sami_label = "SystemAssignedManagedIdentity"
                self.graph.add_node(
                    node_id=sami_node_id,
                    name=sami_label,
                    node_type="SystemAssignedManagedIdentity",
                    color=RESOURCE_COLORS.get("SystemAssignedManagedIdentity")
                )
                self.graph.add_edge(resource_id, sami_node_id, "SystemAssignedMI", color="#98df8a")
                # Link to principal node
                pid_to_name = self.get_principal_names([sys_assigned_principal_id])
                display_name = pid_to_name[sys_assigned_principal_id]
                self.graph.add_node(
                    node_id=sys_assigned_principal_id,
                    name=display_name,
                    node_type="Principal",
                    color=RESOURCE_COLORS.get("Principal")
                )
                self.graph.add_edge(sami_node_id, sys_assigned_principal_id, "Linked", color="blue")

        # If resource has UserAssigned identities
        if "UserAssigned" in identity_type:
            user_assigned_dict = identity_data.get("userAssignedIdentities", {})
            for uami_id, uami_info in user_assigned_dict.items():
                name_part = uami_id.split("/")[-1] or uami_id
                self.graph.add_node(
                    node_id=uami_id,
                    name=name_part,
                    node_type="UserAssignedManagedIdentity",
                    color=RESOURCE_COLORS.get("UserAssignedManagedIdentity")
                )
                self.graph.add_edge(resource_id, uami_id, "Uses UAMI", color="#ff7f0e")

                # Link to principal
                uami_principal_id = uami_info.get("principalId")
                if uami_principal_id:
                    pid_to_name = self.get_principal_names([uami_principal_id])
                    principal_display_name = pid_to_name[uami_principal_id]
                    self.graph.add_node(
                        node_id=uami_principal_id,
                        name=principal_display_name,
                        node_type="Principal",
                        color=RESOURCE_COLORS.get("Principal")
                    )
                    self.graph.add_edge(uami_id, uami_principal_id, "Linked", color="blue")

                # Also fetch Federated Credentials for that UAMI
                fed_creds = self.fetch_federated_credentials_for_uami(uami_id)
                for fc in fed_creds:
                    fc_name = fc.get("name", "unknownFederatedCred")
                    fc_id = f"{uami_id}/federatedCredentials/{fc_name}"
                    self.graph.add_node(
                        fc_id,
                        fc_name,
                        "FederatedCredential",
                        color=RESOURCE_COLORS.get("FederatedCredential")
                    )
                    self.graph.add_edge(uami_id, fc_id, "Federated Credentials", color="#9edae5")

    #########################################################################
    #  OPTIONAL: LINK PRINCIPALS & UAMIs BY THE SAME NAME
    #########################################################################
    def link_principals_uamis_by_name(self):
        principals_by_label = {}
        uamis_by_label = {}
        for node in self.graph.nodes:
            ntype = node["type"]
            label = node["label"]
            nid   = node["id"]
            normalized_label = label.strip().lower()
            if ntype == "Principal":
                principals_by_label.setdefault(normalized_label, []).append((nid, label))
            elif ntype == "UserAssignedManagedIdentity":
                uamis_by_label.setdefault(normalized_label, []).append((nid, label))

        common_labels = set(principals_by_label.keys()).intersection(uamis_by_label.keys())
        print(f"[DEBUG] Found {len(principals_by_label)} principal label(s), "
              f"{len(uamis_by_label)} UAMI label(s). "
              f"Common labels: {common_labels if common_labels else 'None'}")

        for normalized_label in common_labels:
            principal_list = principals_by_label[normalized_label]
            uami_list      = uamis_by_label[normalized_label]
            print(f"[DEBUG] MATCHED LABEL '{normalized_label}' -> "
                  f"Principals={len(principal_list)}, UAMIs={len(uami_list)}")
            for (principal_id, principal_label) in principal_list:
                for (uami_id, uami_label) in uami_list:
                    self.graph.add_edge(principal_id, uami_id, "Linked", color="blue")
                    print(f"[DEBUG] Created Linked edge between "
                          f"Principal:'{principal_label}' <-> UAMI:'{uami_label}'")

    #########################################################################
    #  FINAL PASS: LINK UAMI->PRINCIPAL BY REAL principalId
    #########################################################################
    def link_uami_principals_by_id(self):
        """
        For each User Assigned Managed Identity node, call 'az identity show --ids <uamiResourceId>'
        to retrieve principalId, then create a Principal node (if missing) and link them.
        """
        print("[DEBUG] Starting final UAMI->Principal linking via 'az identity show' ...")
        uami_ids = []
        for node in self.graph.nodes:
            if (node["type"].lower() == "microsoft.managedidentity/userassignedidentities" or 
                node["type"] == "UserAssignedManagedIdentity"):
                uami_ids.append(node["id"])

        if not uami_ids:
            print("[DEBUG] No UserAssignedManagedIdentity nodes found.")
            return

        print(f"[DEBUG] Found {len(uami_ids)} UAMI nodes to process.")
        for uami_resource_id in uami_ids:
            cmd = (
                f"az identity show "
                f"--ids \"{uami_resource_id}\" "
                f"--query principalId "
                f"--output tsv"
            )
            result = self.cli.run_az_cli(cmd)
            principal_id = None
            if isinstance(result, str) and result.strip():
                principal_id = result.strip()
            elif isinstance(result, list) and result:
                principal_id = result[0].strip()
            elif isinstance(result, dict):
                principal_id = result.get("principalId")

            if not principal_id:
                print(f"[DEBUG] UAMI {uami_resource_id} has no principalId.")
                continue

            pid_to_name = self.get_principal_names([principal_id])
            display_name = pid_to_name[principal_id]
            self.graph.add_node(principal_id, display_name, "Principal", RESOURCE_COLORS.get("Principal"))
            self.graph.add_edge(uami_resource_id, principal_id, "Linked", color="blue")
            print(f"[DEBUG] Linked UAMI '{uami_resource_id}' -> Principal '{display_name}' ({principal_id})")

    #########################################################################
    #                           MAIN PROCESS LOGIC
    #########################################################################
    def process_subscription(self, subscription_id: str, subscription_name: str, resource_types: List[str]):
        print(f"\n[INFO] Processing subscription: {subscription_name} ({subscription_id}) ...")
        subscription_node_id = f"/subscriptions/{subscription_id}"
        self.graph.add_node(subscription_node_id, subscription_name, "Subscription", color=RESOURCE_COLORS.get("Subscription"))
        print("[INFO] Processing SUBSCRIPTION-level RBAC...")
        self.process_iam_for_scope(subscription_node_id)

        print("[INFO] Fetching resources from ARG...")
        command = (
            'az graph query -q "Resources '
            '| project id, name, type, resourceGroup, subscriptionId, identity" '
            f"--subscriptions {subscription_id} --output json"
        )
        raw_result = self.cli.run_az_cli(command)
        if isinstance(raw_result, dict):
            resources = raw_result.get("data", [])
        elif isinstance(raw_result, list):
            resources = raw_result
        else:
            resources = []
            print(f"[WARNING] Unexpected result type for subscription {subscription_id}: {type(raw_result)}")

        print(f"[INFO] Found {len(resources)} resources in subscription {subscription_name}.")
        processed_rgs = set()
        for resource in resources:
            if not isinstance(resource, dict):
                continue
            resource_id = resource["id"]
            resource_name = resource["name"]
            resource_type = resource["type"]
            rg_name = resource["resourceGroup"]
            resource_group_id = f"/subscriptions/{subscription_id}/resourceGroups/{rg_name}"

            # Add RG node/edge (if not present)
            self.graph.add_node(resource_group_id, rg_name, "ResourceGroup", RESOURCE_COLORS.get("ResourceGroup"))
            self.graph.add_edge(subscription_node_id, resource_group_id, "Contains", color="#7f7f7f")

            # Process RG-level IAM once
            if resource_group_id not in processed_rgs:
                print(f"[INFO] Processing RBAC for resource group {rg_name} ...")
                self.process_iam_for_scope(resource_group_id)
                processed_rgs.add(resource_group_id)

            # If this resource is not in the resource_types we care about, skip
            if resource_type.lower() not in [t.lower() for t in resource_types]:
                continue

            # Determine color from dictionary
            normalized_type = resource_type.lower()
            matched_type = next((k for k in RESOURCE_COLORS if k.lower() == normalized_type), resource_type)
            resource_color = RESOURCE_COLORS.get(matched_type, "#1f77b4")

            # Add the resource node
            self.graph.add_node(resource_id, resource_name, matched_type, color=resource_color)
            self.graph.add_edge(resource_group_id, resource_id, "Contains", color=resource_color)

            # If it's a "Microsoft.ManagedIdentity/userAssignedIdentities" resource itself,
            # process it with our new logic, then skip the default identity flow.
            if normalized_type == "microsoft.managedidentity/userassignedidentities":
                print(f"[INFO] Processing a user-assigned identity resource: {resource_name}")
                self.process_uami_resource(resource)
                continue

            # Process resource-level RBAC
            print(f"[INFO] Processing RBAC for resource {resource_name} ({resource_type}) ...")
            self.process_iam_for_scope(resource_id)

            # Process (system/user assigned) identity blocks
            self.process_resource_identities(resource)

            # If KeyVault, process Access Policies
            if matched_type.lower() == "microsoft.keyvault/vaults":
                print(f"[INFO] Processing Key Vault access policies for {resource_name} ...")
                self.process_key_vault_access_policies(resource_id)

        print(f"[INFO] Finished subscription: {subscription_name} ({subscription_id})")

    def process_all_subscriptions(self, resource_types: List[str]):
        subscriptions = self.cli.run_az_cli("az account list --output json")
        if not subscriptions:
            print("No subscriptions found.")
            return
        print(f"[INFO] Found {len(subscriptions)} subscriptions to process.")
        with ThreadPoolExecutor() as executor:
            futures = [
                executor.submit(
                    self.process_subscription,
                    subscription["id"],
                    subscription["name"],
                    resource_types
                )
                for subscription in subscriptions
            ]
            for future in futures:
                future.result()


# --------------------------- MAIN EXECUTION --------------------------
if __name__ == "__main__":
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

    graph = AzureResourceGraph()
    cli = AzureCLI()
    processor = AzureResourceProcessor(graph, cli)

    # Gather all resources and build the graph
    processor.process_all_subscriptions(RESOURCE_TYPES)

    # OPTIONAL: link Principals & UAMIs by same display label
    processor.link_principals_uamis_by_name()

    # DEFINITIVE: link UAMI -> Principal by principalId from 'az identity show'
    processor.link_uami_principals_by_id()

    # Write final JSON
    processor.graph.write_to_file("output_azure_resource_data.json")
