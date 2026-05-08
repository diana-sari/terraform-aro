variable "name_prefix" {
  type        = string
  description = "Prefix for resource names (typically the ARO cluster name)."
}

variable "location" {
  type        = string
  description = "Azure region for the resource group and virtual network."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to the resource group, VNet, subnets, and NSG."
}

variable "aro_virtual_network_cidr_block" {
  type        = string
  description = "CIDR block for the ARO virtual network."
}

variable "aro_control_subnet_cidr_block" {
  type        = string
  description = "CIDR block for the ARO control plane subnet."
}

variable "aro_machine_subnet_cidr_block" {
  type        = string
  description = "CIDR block for the ARO worker (machine) subnet."
}

variable "enable_managed_identities" {
  type        = bool
  description = "When true, subnet NSG associations are omitted (ARO managed identity requirement)."
}
