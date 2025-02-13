<#
.SYNOPSIS
   Generates an HTML report of custom Azure RBAC roles.

.DESCRIPTION
   This function queries all subscriptions accessible by the current Azure account to retrieve custom Azure RBAC roles.
   It compiles data on roles, assignments, permissions, and scopes into an interactive HTML report using DataTables.

.PARAMETER OutputFilePath
   Specifies the file path where the HTML report will be saved. Defaults to "CustomAzureRBACRoles.html".

.EXAMPLE
   Invoke-AzRBACListCustomRoles -OutputFilePath "C:\Temp\CustomAzureRBACRoles.html"
   Generates the report and saves it to the specified location.

.NOTES
   - Requires the Az PowerShell module (will be installed automatically if missing).
   - Make sure you're connected to Azure (e.g., via Connect-AzAccount) before running the function.
   - Author: Your Name
   - Date: 2025-02-12
#>

function Invoke-AzRBACListCustomRoles {
    [CmdletBinding()]
    param (
        [string]$OutputFilePath = "CustomAzureRBACRoles.html"
    )

    Write-Host "Generating HTML report..." -ForegroundColor Green

    # Install the Az module if not already installed.
    if (-not (Get-Module -Name Az -ListAvailable)) {
        Install-Module -Name Az -AllowClobber -Scope CurrentUser -Force
    }

    # Connect to Azure if not already connected.
    # Connect-AzAccount

    # Get all subscriptions the user has access to.
    $subscriptions = Get-AzSubscription

    # Initialize an array to store all custom roles.
    $allCustomRoles = @()

    # Loop through each subscription.
    foreach ($subscription in $subscriptions) {
        Write-Output "Checking subscription: $($subscription.Name) (ID: $($subscription.Id))"

        try {
            # Set the context to the current subscription.
            Set-AzContext -SubscriptionId $subscription.Id -ErrorAction Stop | Out-Null

            # Get all custom roles in the current subscription.
            $customRoles = Get-AzRoleDefinition -ErrorAction Stop | Where-Object { $_.IsCustom -eq $true }
        }
        catch {
            Write-Warning "Skipping subscription '$($subscription.Name)' (ID: $($subscription.Id)) due to error: $($_.Exception.Message)"
            continue
        }

        # Add the subscription info to each role for tracking.
        $customRoles | ForEach-Object {
            $_ | Add-Member -NotePropertyName "SubscriptionId" -NotePropertyValue $subscription.Id -Force
            $_ | Add-Member -NotePropertyName "SubscriptionName" -NotePropertyValue $subscription.Name -Force
        }

        # Append these roles to the overall array.
        $allCustomRoles += $customRoles
    }

    # Build HTML table rows for each custom role.
    $htmlRows = ""
    foreach ($role in $allCustomRoles) {
        try {
            # Set the context for role assignments (to capture scopes like resource groups or resources).
            Set-AzContext -SubscriptionId $role.SubscriptionId -ErrorAction Stop | Out-Null

            # Get role assignments for this role.
            $assignments = Get-AzRoleAssignment -RoleDefinitionName $role.Name -ErrorAction Stop
        }
        catch {
            Write-Warning "Error retrieving role assignments for role '$($role.Name)' in subscription '$($role.SubscriptionName)'. Skipping assignment details for this role. Error: $($_.Exception.Message)"
            $assignments = @()
        }

        # Build a comma-separated list of "DisplayName (ObjectType)" from assignments.
        $assignedDetails = $assignments | ForEach-Object {
            "$($_.DisplayName) ($($_.ObjectType))"
        }
        $assignedDetailsText = ($assignedDetails | Sort-Object | Get-Unique) -join ", "

        # Build a comma-separated list of unique scopes from assignments.
        $scopes = $assignments | Select-Object -ExpandProperty Scope | Sort-Object | Get-Unique
        $scopesText = $scopes -join ", "

        # If no assignment scopes are found, display the assignable scopes from the role definition.
        if ([string]::IsNullOrEmpty($scopesText)) {
            if ($role.AssignableScopes -and $role.AssignableScopes.Count -gt 0) {
                $scopesText = "No assignments found. Role defined with assignable scope(s): " + ($role.AssignableScopes -join ", ")
            }
            else {
                $scopesText = "No assignments found."
            }
        }

        # Get role permissions and replace commas with HTML line breaks for readability.
        $permissions = ($role.Actions -join ", ").Replace(",", "<br>")

        $htmlRows += "<tr>"
        $htmlRows += "<td>$($role.SubscriptionName)</td>"
        $htmlRows += "<td>$($role.Name)</td>"
        $htmlRows += "<td>$($role.Description)</td>"
        $htmlRows += "<td>$assignedDetailsText</td>"
        $htmlRows += "<td>$permissions</td>"
        $htmlRows += "<td>$scopesText</td>"
        $htmlRows += "</tr>"
    }

    # Construct full HTML content with adjustable (resizable) columns.
    $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>Custom Azure RBAC Roles Report</title>
    <!-- DataTables CSS -->
    <link rel="stylesheet" href="https://cdn.datatables.net/1.13.4/css/jquery.dataTables.min.css">
    <!-- jquery-resizable-columns CSS -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/jquery-resizable-columns@0.2.3/dist/jquery.resizableColumns.css">
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { width: 100%; border-collapse: collapse; }
        th, td { border: 1px solid #ddd; padding: 8px; vertical-align: top; text-align: left; }
        th { background-color: #007FFF; color: white; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        tr:hover { background-color: #f1f1f1; }
    </style>
    <!-- jQuery and DataTables -->
    <script src="https://code.jquery.com/jquery-3.6.4.min.js"></script>
    <script src="https://cdn.datatables.net/1.13.4/js/jquery.dataTables.min.js"></script>
    <!-- jquery-resizable-columns JS -->
    <script src="https://cdn.jsdelivr.net/npm/jquery-resizable-columns@0.2.3/dist/jquery.resizableColumns.min.js"></script>
    <script>
        $(document).ready(function () {
            var table = $('#rolesTable').DataTable({
                orderCellsTop: true,
                fixedHeader: true
            });
            // Enable adjustable (resizable) columns on the table.
            $('#rolesTable').resizableColumns();
        });
    </script>
</head>
<body>
    <h1 style="color: #007FFF;">🍲 Custom Azure RBAC Roles Report 📝</h1>
    <table id="rolesTable" class="display" style="width:100%">
        <thead>
            <tr>
                <th>Subscription Name</th>
                <th>Role Name</th>
                <th>Description</th>
                <th>Assigned Users/Groups/Service Principals</th>
                <th>Permissions</th>
                <th>Scope</th>
            </tr>
        </thead>
        <tbody>
$htmlRows
        </tbody>
    </table>
</body>
</html>
"@

    # Save the HTML report to the specified file and open it.
    $htmlContent | Out-File -FilePath $OutputFilePath -Encoding UTF8
    Write-Host "Report generated: $OutputFilePath" -ForegroundColor Blue
    Start-Process $OutputFilePath
}
