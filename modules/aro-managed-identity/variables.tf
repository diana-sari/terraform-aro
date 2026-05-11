variable "location" {
  type        = string
  description = "The Azure region where the resources will be created."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group where the identities will be created."
}

variable "identity_names" {
  type        = map(string)
  description = "A map of logical names to actual names for the user-assigned managed identities."
  default = {
    cloud_controller_manager = "cloud-controller-manager"
    ingress                  = "ingress"
    machine_api              = "machine-api"
    disk_csi_driver          = "disk-csi-driver"
    cloud_network_config     = "cloud-network-config"
    image_registry           = "image-registry"
    file_csi_driver          = "file-csi-driver"
    aro_operator             = "aro-operator"
    cluster_msi              = "cluster"
  }
}
