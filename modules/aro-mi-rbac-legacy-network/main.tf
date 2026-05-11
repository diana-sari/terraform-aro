#
# Legacy-style RBAC for ARO managed identities: Network Contributor (or optional minimal custom
# network roles) plus Managed Identity Operator from cluster_msi to platform identities.
# Aligned with modules/aro-managed-identity-permissions/30-permissions.tf, but identities are
# created elsewhere (reference/aro-azapi/modules/managed_identity).
#

locals {
  has_custom_network_role    = var.minimal_network_role != null && var.minimal_network_role != ""
  has_network_security_group = var.network_security_group_id != null && var.network_security_group_id != ""

  vnet_permissions = [
    "Microsoft.Network/virtualNetworks/join/action",
    "Microsoft.Network/virtualNetworks/read"
  ]

  subnet_permissions = [
    "Microsoft.Network/virtualNetworks/subnets/join/action",
    "Microsoft.Network/virtualNetworks/subnets/read",
    "Microsoft.Network/virtualNetworks/subnets/write"
  ]

  route_table_permissions = [
    "Microsoft.Network/routeTables/join/action",
    "Microsoft.Network/routeTables/read"
  ]

  nat_gateway_permissions = [
    "Microsoft.Network/natGateways/join/action",
    "Microsoft.Network/natGateways/read"
  ]

  network_security_group_permissions = [
    "Microsoft.Network/networkSecurityGroups/join/action"
  ]

  route_table_map = { for idx, rt_id in var.route_table_ids : tostring(idx) => rt_id }
  nat_gateway_map = { for idx, ng_id in var.nat_gateway_ids : tostring(idx) => ng_id }

  managed_identity_operator_role_id = "ef318e2a-8334-4a05-9e4a-295a196c6a6e"
}

resource "azurerm_role_definition" "network" {
  count = local.has_custom_network_role ? 1 : 0

  name              = var.minimal_network_role
  description       = "Custom role for ARO network for cluster: ${var.cluster_name}"
  scope             = var.vnet_id
  assignable_scopes = [var.vnet_id]

  permissions {
    actions = local.vnet_permissions
  }
}

resource "azurerm_role_definition" "subnet" {
  count = local.has_custom_network_role ? 1 : 0

  name              = "${var.minimal_network_role}-subnet"
  description       = "Custom role for ARO network subnets for cluster: ${var.cluster_name}"
  scope             = var.vnet_id
  assignable_scopes = [var.vnet_id]

  permissions {
    actions = local.subnet_permissions
  }
}

resource "azurerm_role_definition" "network_route_tables" {
  count = local.has_custom_network_role ? length(var.route_table_ids) : 0

  name              = "${var.minimal_network_role}-route-table-${count.index}"
  description       = "Custom role for ARO route table index ${count.index} for cluster: ${var.cluster_name}"
  scope             = var.route_table_ids[count.index]
  assignable_scopes = [var.route_table_ids[count.index]]

  permissions {
    actions = local.route_table_permissions
  }
}

resource "azurerm_role_definition" "network_nat_gateways" {
  count = local.has_custom_network_role ? length(var.nat_gateway_ids) : 0

  name              = "${var.minimal_network_role}-nat-gateway-${count.index}"
  description       = "Custom role for ARO NAT gateway index ${count.index} for cluster: ${var.cluster_name}"
  scope             = var.nat_gateway_ids[count.index]
  assignable_scopes = [var.nat_gateway_ids[count.index]]

  permissions {
    actions = local.nat_gateway_permissions
  }
}

resource "azurerm_role_definition" "network_network_security_group" {
  count = local.has_custom_network_role && local.has_network_security_group ? 1 : 0

  name              = "${var.minimal_network_role}-nsg"
  description       = "Custom role for ARO network security group for cluster: ${var.cluster_name}"
  scope             = var.network_security_group_id
  assignable_scopes = [var.network_security_group_id]

  permissions {
    actions = local.network_security_group_permissions
  }
}

# VNet — cloud-network-config, file-csi-driver, image-registry
resource "azurerm_role_assignment" "vnet_cloud_network_config" {
  scope                            = var.vnet_id
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.network[0].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = var.identity_principal_ids["cloud_network_config"]
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "vnet_file_csi_driver" {
  scope                            = var.vnet_id
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.network[0].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = var.identity_principal_ids["file_csi_driver"]
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "vnet_image_registry" {
  scope                            = var.vnet_id
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.network[0].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = var.identity_principal_ids["image_registry"]
  skip_service_principal_aad_check = true
}

# Subnets — aro-operator, cloud-controller-manager, cloud-network-config, file-csi-driver, ingress, machine-api, image-registry
resource "azurerm_role_assignment" "subnet_aro_operator" {
  for_each = var.subnet_ids

  scope                            = each.value
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.subnet[0].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = var.identity_principal_ids["aro_operator"]
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "subnet_cloud_controller_manager" {
  for_each = var.subnet_ids

  scope                            = each.value
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.subnet[0].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = var.identity_principal_ids["cloud_controller_manager"]
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "subnet_cloud_network_config" {
  for_each = var.subnet_ids

  scope                            = each.value
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.subnet[0].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = var.identity_principal_ids["cloud_network_config"]
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "subnet_file_csi_driver" {
  for_each = var.subnet_ids

  scope                            = each.value
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.subnet[0].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = var.identity_principal_ids["file_csi_driver"]
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "subnet_ingress" {
  for_each = var.subnet_ids

  scope                            = each.value
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.subnet[0].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = var.identity_principal_ids["ingress"]
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "subnet_machine_api" {
  for_each = var.subnet_ids

  scope                            = each.value
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.subnet[0].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = var.identity_principal_ids["machine_api"]
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "subnet_image_registry" {
  for_each = var.subnet_ids

  scope                            = each.value
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.subnet[0].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = var.identity_principal_ids["image_registry"]
  skip_service_principal_aad_check = true
}

# Route tables — aro-operator, cloud-controller-manager, file-csi-driver, machine-api
resource "azurerm_role_assignment" "route_table_aro_operator" {
  for_each = local.route_table_map

  scope                            = each.value
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.network_route_tables[tonumber(each.key)].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = var.identity_principal_ids["aro_operator"]
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "route_table_cloud_controller_manager" {
  for_each = local.route_table_map

  scope                            = each.value
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.network_route_tables[tonumber(each.key)].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = var.identity_principal_ids["cloud_controller_manager"]
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "route_table_file_csi_driver" {
  for_each = local.route_table_map

  scope                            = each.value
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.network_route_tables[tonumber(each.key)].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = var.identity_principal_ids["file_csi_driver"]
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "route_table_machine_api" {
  for_each = local.route_table_map

  scope                            = each.value
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.network_route_tables[tonumber(each.key)].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = var.identity_principal_ids["machine_api"]
  skip_service_principal_aad_check = true
}

# NAT gateways — aro-operator, file-csi-driver
resource "azurerm_role_assignment" "nat_gateway_aro_operator" {
  for_each = local.nat_gateway_map

  scope                            = each.value
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.network_nat_gateways[tonumber(each.key)].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = var.identity_principal_ids["aro_operator"]
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "nat_gateway_file_csi_driver" {
  for_each = local.nat_gateway_map

  scope                            = each.value
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.network_nat_gateways[tonumber(each.key)].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = var.identity_principal_ids["file_csi_driver"]
  skip_service_principal_aad_check = true
}

# NSG — aro-operator, cloud-controller-manager, file-csi-driver, machine-api
resource "azurerm_role_assignment" "nsg_aro_operator" {
  count = local.has_network_security_group ? 1 : 0

  scope                            = var.network_security_group_id
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.network_network_security_group[0].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = var.identity_principal_ids["aro_operator"]
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "nsg_cloud_controller_manager" {
  count = local.has_network_security_group ? 1 : 0

  scope                            = var.network_security_group_id
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.network_network_security_group[0].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = var.identity_principal_ids["cloud_controller_manager"]
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "nsg_file_csi_driver" {
  count = local.has_network_security_group ? 1 : 0

  scope                            = var.network_security_group_id
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.network_network_security_group[0].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = var.identity_principal_ids["file_csi_driver"]
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "nsg_machine_api" {
  count = local.has_network_security_group ? 1 : 0

  scope                            = var.network_security_group_id
  role_definition_id               = local.has_custom_network_role ? azurerm_role_definition.network_network_security_group[0].role_definition_resource_id : null
  role_definition_name             = local.has_custom_network_role ? null : "Network Contributor"
  principal_id                     = var.identity_principal_ids["machine_api"]
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "installer_aro_resource_group" {
  count = var.assign_installer_contributor_to_aro_rg ? 1 : 0

  scope                = var.aro_resource_group_id
  role_definition_name = "Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

# ARO resource provider — same network scopes as legacy MI module
resource "azurerm_role_assignment" "resource_provider_vnet" {
  scope                = var.vnet_id
  role_definition_id   = local.has_custom_network_role ? azurerm_role_definition.network[0].role_definition_resource_id : null
  role_definition_name = local.has_custom_network_role ? null : "Network Contributor"
  principal_id         = var.aro_rp_object_id
}

resource "azurerm_role_assignment" "resource_provider_route_tables" {
  for_each = local.route_table_map

  scope                = each.value
  role_definition_id   = local.has_custom_network_role ? azurerm_role_definition.network_route_tables[tonumber(each.key)].role_definition_resource_id : null
  role_definition_name = local.has_custom_network_role ? null : "Network Contributor"
  principal_id         = var.aro_rp_object_id
}

resource "azurerm_role_assignment" "resource_provider_nat_gateways" {
  for_each = local.nat_gateway_map

  scope                = each.value
  role_definition_id   = local.has_custom_network_role ? azurerm_role_definition.network_nat_gateways[tonumber(each.key)].role_definition_resource_id : null
  role_definition_name = local.has_custom_network_role ? null : "Network Contributor"
  principal_id         = var.aro_rp_object_id
}

resource "azurerm_role_assignment" "resource_provider_network_security_group" {
  count = local.has_network_security_group ? 1 : 0

  scope                = var.network_security_group_id
  role_definition_id   = local.has_custom_network_role ? azurerm_role_definition.network_network_security_group[0].role_definition_resource_id : null
  role_definition_name = local.has_custom_network_role ? null : "Network Contributor"
  principal_id         = var.aro_rp_object_id
}

# Cluster MSI — Managed Identity Operator on platform identities (legacy parity; excludes cluster_msi itself)
resource "azurerm_role_assignment" "cluster_to_cloud_controller_manager" {
  scope              = var.identity_resource_ids["cloud_controller_manager"]
  role_definition_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${local.managed_identity_operator_role_id}"
  principal_id       = var.identity_principal_ids["cluster_msi"]
  principal_type     = "ServicePrincipal"
}

resource "azurerm_role_assignment" "cluster_to_ingress" {
  scope              = var.identity_resource_ids["ingress"]
  role_definition_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${local.managed_identity_operator_role_id}"
  principal_id       = var.identity_principal_ids["cluster_msi"]
  principal_type     = "ServicePrincipal"
}

resource "azurerm_role_assignment" "cluster_to_machine_api" {
  scope              = var.identity_resource_ids["machine_api"]
  role_definition_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${local.managed_identity_operator_role_id}"
  principal_id       = var.identity_principal_ids["cluster_msi"]
  principal_type     = "ServicePrincipal"
}

resource "azurerm_role_assignment" "cluster_to_disk_csi_driver" {
  scope              = var.identity_resource_ids["disk_csi_driver"]
  role_definition_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${local.managed_identity_operator_role_id}"
  principal_id       = var.identity_principal_ids["cluster_msi"]
  principal_type     = "ServicePrincipal"
}

resource "azurerm_role_assignment" "cluster_to_cloud_network_config" {
  scope              = var.identity_resource_ids["cloud_network_config"]
  role_definition_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${local.managed_identity_operator_role_id}"
  principal_id       = var.identity_principal_ids["cluster_msi"]
  principal_type     = "ServicePrincipal"
}

resource "azurerm_role_assignment" "cluster_to_image_registry" {
  scope              = var.identity_resource_ids["image_registry"]
  role_definition_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${local.managed_identity_operator_role_id}"
  principal_id       = var.identity_principal_ids["cluster_msi"]
  principal_type     = "ServicePrincipal"
}

resource "azurerm_role_assignment" "cluster_to_file_csi_driver" {
  scope              = var.identity_resource_ids["file_csi_driver"]
  role_definition_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${local.managed_identity_operator_role_id}"
  principal_id       = var.identity_principal_ids["cluster_msi"]
  principal_type     = "ServicePrincipal"
}

resource "azurerm_role_assignment" "cluster_to_aro_operator" {
  scope              = var.identity_resource_ids["aro_operator"]
  role_definition_id = "/subscriptions/${var.subscription_id}/providers/Microsoft.Authorization/roleDefinitions/${local.managed_identity_operator_role_id}"
  principal_id       = var.identity_principal_ids["cluster_msi"]
  principal_type     = "ServicePrincipal"
}
