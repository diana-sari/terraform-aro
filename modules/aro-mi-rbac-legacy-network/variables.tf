variable "cluster_name" {
  type        = string
  description = "Cluster name (used in custom role descriptions and role definition name suffixes)."
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription ID (for Managed Identity Operator role definition path)."
}

variable "aro_resource_group_id" {
  type        = string
  description = "Resource ID of the ARO resource group (installer Contributor assignment scope)."
}

variable "vnet_id" {
  type        = string
  description = "Virtual network resource ID."
}

variable "subnet_ids" {
  type        = set(string)
  description = "Subnet resource IDs (typically control plane and worker subnets)."
}

variable "network_security_group_id" {
  type        = string
  description = "NSG resource ID for BYO-NSG / preconfigured NSG scenarios."
}

variable "route_table_ids" {
  type        = list(string)
  default     = []
  description = "Route table resource IDs (UDR / restrict egress). Empty when not using route tables."
}

variable "nat_gateway_ids" {
  type        = list(string)
  default     = []
  description = "NAT gateway resource IDs. Usually empty for this repo; supported for parity with legacy MI permissions."
}

variable "minimal_network_role" {
  type        = string
  default     = null
  description = "If set, create scoped custom role definitions instead of assigning built-in Network Contributor on network objects."
}

variable "aro_rp_object_id" {
  type        = string
  description = "Object ID of the Azure Red Hat OpenShift resource provider service principal."
}

variable "identity_principal_ids" {
  type        = map(string)
  description = <<-EOT
    Principal IDs from reference/managed_identity (logical keys): aro_operator, cloud_controller_manager,
    cloud_network_config, cluster_msi, disk_csi_driver, file_csi_driver, image_registry, ingress, machine_api.
  EOT
}

variable "identity_resource_ids" {
  type        = map(string)
  description = <<-EOT
    Full ARM resource IDs of the same user-assigned identities (for Managed Identity Operator assignment scopes).
  EOT
}

variable "assign_installer_contributor_to_aro_rg" {
  type        = bool
  default     = true
  description = "Grant the current Terraform principal Contributor on the ARO resource group (legacy MI module behavior)."
}
