locals {
  aro_federated_credential_role_definition_id = "ef318e2a-8334-4a05-9e4a-295a196c6a6e"
  # Use the display name here (not hand-built role_definition_id strings) so refreshes match ARM;
  # mismatched subscription-scoped paths vs API-normalized IDs caused perpetual replace loops.
  aro_federated_credential_role_definition_name = "Azure Red Hat OpenShift Federated Credential"
  cluster_msi_key                               = "cluster_msi"
  other_identity_keys = toset([
    for k in keys(var.identity_names) : k if k != local.cluster_msi_key
  ])
}

resource "azurerm_user_assigned_identity" "identities" {
  for_each = var.identity_names

  name                = each.value
  resource_group_name = var.resource_group_name
  location            = var.location

  lifecycle {
    ignore_changes = [
      tags,
    ]
  }
}

resource "random_uuid" "role_assignment_names" {
  for_each = local.other_identity_keys

  keepers = {
    scope        = azurerm_user_assigned_identity.identities[each.key].id
    principal_id = azurerm_user_assigned_identity.identities[local.cluster_msi_key].principal_id
    role_def_id  = local.aro_federated_credential_role_definition_id
    # Role assignments are immutable per ARM; the assignment `name` is the GUID PK. Changing how we declare
    # the role (built path id vs lookup by name, etc.) must yield a NEW UUID or Terraform emits an UPDATE
    # against the existing GUID → Azure responds "doesn't support update".
    role_assignment_authoring = "builtin_name_v1"
  }
}

resource "azurerm_role_assignment" "cluster_msi_role_assignments" {
  for_each = local.other_identity_keys

  name  = random_uuid.role_assignment_names[each.key].result
  scope = azurerm_user_assigned_identity.identities[each.key].id

  role_definition_name             = local.aro_federated_credential_role_definition_name
  principal_id                     = azurerm_user_assigned_identity.identities[local.cluster_msi_key].principal_id
  principal_type                   = "ServicePrincipal"
  skip_service_principal_aad_check = true

  depends_on = [random_uuid.role_assignment_names]
}
