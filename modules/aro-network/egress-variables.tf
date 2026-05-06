# Egress / Azure Firewall inputs (names differ from root variables to avoid terraform-ls false diagnostics)
variable "egress_traffic_restricted" {
  type        = bool
  default     = false
  description = "When true, creates Azure Firewall, UDR, and route table associations for ARO subnets (egress restriction). Root passes var.restrict_egress_traffic."
}

variable "firewall_subnet_cidr_block" {
  type        = string
  description = "CIDR for AzureFirewallSubnet; must fit inside the VNet and not overlap other subnets. Used only when egress_traffic_restricted is true."
}
