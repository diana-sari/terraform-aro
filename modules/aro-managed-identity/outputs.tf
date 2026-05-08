output "identity_principal_ids" {
  description = "A map of logical identity names to their principal IDs."
  value = {
    for k, identity in azurerm_user_assigned_identity.identities : k => identity.principal_id
  }
}

output "identity_resource_ids" {
  description = "A map of logical identity names to their Resource IDs."
  value = {
    for k, identity in azurerm_user_assigned_identity.identities : k => identity.id
  }
}
