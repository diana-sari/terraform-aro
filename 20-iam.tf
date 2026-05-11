data "azurerm_client_config" "current" {}

# NOTE: we need to store a single input that we pass into the aro_permissions module because
#       modules cannot use depends_on and we need to ensure all of our objects have been
#       created prior to setting permissions/policies
resource "terraform_data" "aro_permission_wait" {
  input = {
    cluster_name = var.cluster_name
  }

  # ensure that we create all of our objects before attempting to apply policies that restrict
  # their creation
  depends_on = [
    module.aro_network,
    azurerm_subnet.jumphost_subnet,
    azurerm_subnet.private_endpoint_subnet,
  ]
}

# Service Principal Permissions Module (when managed identities are disabled)
# Vendored module: terraform-aro-permissions v0.2.1 (modernized)
# Original source: https://github.com/rh-mobb/terraform-aro-permissions.git?ref=v0.2.1
# NOTE: Module has been modernized to remove provider blocks, allowing count/for_each usage
# NOTE: depends_on cluster ensures cluster is deleted FIRST during destroy (reverse dependency order)
module "aro_permissions" {
  count = var.enable_managed_identities ? 0 : 1

  source = "./modules/aro-permissions"

  # NOTE: terraform installation == 'api' installation_type (as opposed to 'cli')
  installation_type = "api"

  # do not output the credentials to a file
  output_as_file = true

  # Built-in Network Contributor (VNet, subnets, NSG, route tables, …) and Contributor (ARO RG) for
  # cluster + installer + ARO resource provider—aligned with Microsoft tutorial guidance.
  # See: https://learn.microsoft.com/en-us/azure/openshift/tutorial-create-cluster#verify-your-permissions
  # Omit minimal_network_role / minimal_aro_role to use those defaults (module 01-variables.tf).

  # cluster parameters
  cluster_name           = terraform_data.aro_permission_wait.output.cluster_name
  vnet                   = module.aro_network.virtual_network_name
  vnet_resource_group    = module.aro_network.resource_group_name
  network_security_group = module.aro_network.network_security_group_name

  aro_resource_group = {
    name   = module.aro_network.resource_group_name
    create = false
  }

  # service principals
  cluster_service_principal = {
    name   = local.cluster_service_principal_name
    create = true
  }

  installer_service_principal = {
    name   = local.installer_service_principal_name
    create = true
  }

  # set custom permissions
  nat_gateways = []
  subnets      = [module.aro_network.control_plane_subnet_name, module.aro_network.machine_subnet_name]
  route_tables = var.restrict_egress_traffic ? [module.aro_network.firewall_route_table_name] : []

  # further restrict via policy
  managed_resource_group   = "${module.aro_network.resource_group_name}-managed"
  apply_vnet_policy        = var.apply_restricted_policies
  apply_subnet_policy      = var.apply_restricted_policies
  apply_route_table_policy = var.apply_restricted_policies
  apply_nat_gateway_policy = var.apply_restricted_policies
  apply_nsg_policy         = var.apply_restricted_policies
  apply_dns_policy         = var.apply_restricted_policies && var.domain != null && var.domain != ""
  apply_private_dns_policy = var.apply_restricted_policies && var.domain != null && var.domain != ""
  apply_public_ip_policy   = var.apply_restricted_policies && var.api_server_profile != "Public" && var.ingress_profile != "Public"

  # explicitly set location, subscription id and tenant id
  location        = var.location
  subscription_id = data.azurerm_client_config.current.subscription_id
  tenant_id       = data.azurerm_client_config.current.tenant_id
}

module "aro_mi_identities" {
  count = var.enable_managed_identities ? 1 : 0

  source = "./modules/aro-managed-identity"

  location            = var.location
  resource_group_name = module.aro_network.resource_group_name
  identity_names      = local.mi_identity_azure_names

  depends_on = [terraform_data.aro_permission_wait]
}

moved {
  from = module.aro_mi_rbac
  to   = module.aro_mi_rbac[0]
}

module "aro_mi_rbac" {
  count = var.enable_managed_identities && var.mi_use_builtin_operator_roles ? 1 : 0

  source = "./modules/aro-mi-rbac"

  aro_vnet_id                        = module.aro_network.virtual_network_id
  control_plane_subnet_id            = module.aro_network.control_plane_subnet_id
  compute_subnet_id                  = module.aro_network.machine_subnet_id
  identity_principal_ids             = module.aro_mi_identities[0].identity_principal_ids
  aro_rp_object_id                   = data.azuread_service_principal.aro_rp.object_id
  route_table_id                     = module.aro_network.firewall_route_table_id
  create_route_table_role_assignment = var.restrict_egress_traffic
  nsg_id                             = module.aro_network.network_security_group_id
  create_nsg_role_assignment         = true

  depends_on = [module.aro_mi_identities]
}

# Legacy-style MI RBAC (Network Contributor or mi_minimal_network_role custom roles + cluster MSI operator wiring).
# Optional alternative when mi_use_builtin_operator_roles is false.
module "aro_mi_rbac_legacy_network" {
  count = var.enable_managed_identities && !var.mi_use_builtin_operator_roles ? 1 : 0

  source = "./modules/aro-mi-rbac-legacy-network"

  cluster_name          = var.cluster_name
  subscription_id       = data.azurerm_client_config.current.subscription_id
  aro_resource_group_id = module.aro_network.resource_group_id
  vnet_id               = module.aro_network.virtual_network_id
  subnet_ids = toset([
    module.aro_network.control_plane_subnet_id,
    module.aro_network.machine_subnet_id,
  ])
  network_security_group_id = module.aro_network.network_security_group_id
  route_table_ids = (
    var.restrict_egress_traffic && module.aro_network.firewall_route_table_id != null
    ? [module.aro_network.firewall_route_table_id]
    : []
  )
  nat_gateway_ids        = []
  minimal_network_role   = var.mi_minimal_network_role
  aro_rp_object_id       = data.azuread_service_principal.aro_rp.object_id
  identity_principal_ids = module.aro_mi_identities[0].identity_principal_ids
  identity_resource_ids  = module.aro_mi_identities[0].identity_resource_ids

  depends_on = [module.aro_mi_identities]
}

#
# NOTE: for whatever reason, in order for the installer provider to consume the password we create in the aro_permissions
#       module, we must sleep here and let things calm down first and pass it through a 'terraform_data' resource (it
#       fails the first time if attempting to use directly but succeeds when continuing to apply)
#
resource "time_sleep" "wait" {
  count = var.enable_managed_identities ? 0 : 1

  create_duration = "10s"

  depends_on = [module.aro_permissions[0]]
}

resource "terraform_data" "installer_credentials" {
  count = var.enable_managed_identities ? 0 : 1

  input = {
    client_id     = module.aro_permissions[0].installer_service_principal_client_id
    client_secret = module.aro_permissions[0].installer_service_principal_client_secret
  }

  depends_on = [time_sleep.wait]
}
