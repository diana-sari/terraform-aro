variable "aro_vnet_id" {
  type        = string
  description = "The ID of the ARO Virtual Network."
}

variable "control_plane_subnet_id" {
  type        = string
  description = "The ID of the ARO control plane subnet."
}

variable "compute_subnet_id" {
  type        = string
  description = "The ID of the ARO compute subnet."
}

variable "identity_principal_ids" {
  type        = map(string)
  description = "A map of logical identity names to their principal IDs."
}

variable "aro_rp_object_id" {
  type        = string
  description = "The object ID of the ARO Resource Provider service principal."
}

variable "route_table_id" {
  type        = string
  description = "The ID of the route table to assign permissions to."
  default     = null
}

variable "create_route_table_role_assignment" {
  type        = bool
  description = "Whether to create the role assignment for the route table. Explicitly required because route_table_id may be computed."
  default     = false
}

variable "nsg_id" {
  type        = string
  description = "The ID of the Network Security Group to assign permissions to."
  default     = null
}

variable "create_nsg_role_assignment" {
  type        = bool
  description = "Whether to create the role assignment for the NSG. Required because nsg_id may be computed."
  default     = false
}
