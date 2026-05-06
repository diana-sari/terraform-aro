variable "cluster_name" {
  type        = string
  description = "The name of the ARO cluster."
}

variable "resource_group_name" {
  type        = string
  description = "The resource group where the cluster is deployed."
}

variable "location" {
  type        = string
  description = "The Azure region."
}

variable "managed_resource_group_name" {
  type        = string
  description = "The name of the resource group that the ARO cluster will create to manage its resources."
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to the cluster."
  default     = {}
}

variable "domain" {
  type        = string
  description = "The domain for the cluster."
}

variable "aro_version" {
  type        = string
  description = "The OpenShift version."
}

variable "pull_secret" {
  type        = string
  description = "The Red Hat pull secret."
  sensitive   = true
}

variable "api_server_visibility" {
  type        = string
  description = "API Server visibility (Public or Private)."
  default     = "Private"
}

variable "ingress_visibility" {
  type        = string
  description = "Ingress visibility (Public or Private)."
  default     = "Private"
}

variable "outbound_type" {
  type        = string
  description = "Outbound egress type: Loadbalancer or UserDefinedRouting. When null, uses Public API -> Loadbalancer else UserDefinedRouting (legacy reference behavior)."
  default     = null
  nullable    = true
}

variable "control_plane_subnet_id" {
  type        = string
  description = "Subnet ID for the control plane."
}

variable "control_plane_vm_size" {
  type        = string
  description = "VM size for the control plane."
  default     = "Standard_D8s_v3"
}

variable "compute_subnet_id" {
  type        = string
  description = "Subnet ID for compute nodes."
}

variable "compute_vm_size" {
  type        = string
  description = "VM size for compute nodes."
  default     = "Standard_D4s_v3"
}

variable "compute_vm_disk_size" {
  type        = number
  description = "Disk size in GB for compute nodes."
  default     = 128
}

variable "compute_node_count" {
  type        = number
  description = "Number of compute nodes."
  default     = 3
}

variable "encryption_at_host" {
  type        = bool
  description = "Enable encryption at host."
  default     = false
}

variable "pod_cidr" {
  type        = string
  description = "CIDR for pods."
  default     = "10.128.0.0/14"
}

variable "service_cidr" {
  type        = string
  description = "CIDR for services."
  default     = "172.30.0.0/16"
}

variable "cluster_msi_resource_id" {
  type        = string
  description = "Resource ID of the user-assigned identity for the cluster itself."
}

variable "platform_workload_identities" {
  type        = map(string)
  description = "Map of operator names to their User Assigned Identity Resource IDs."
}

variable "preconfigured_nsg" {
  type        = string
  description = "Whether a preconfigured NSG is attached to the cluster subnets. Enabled or Disabled."
  default     = "Enabled"
}

variable "timeouts" {
  type = object({
    create = optional(string)
    delete = optional(string)
    read   = optional(string)
    update = optional(string)
  })
  description = "Timeout configurations for the ARO cluster."
  default     = null
}
