output "resource_group_name" {
  description = "Name of the resource group holding the ARO core network."
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "Resource ID of the resource group."
  value       = azurerm_resource_group.main.id
}

output "location" {
  description = "Azure region of the resource group."
  value       = azurerm_resource_group.main.location
}

output "virtual_network_name" {
  description = "Name of the ARO virtual network."
  value       = azurerm_virtual_network.main.name
}

output "virtual_network_id" {
  description = "Resource ID of the ARO virtual network."
  value       = azurerm_virtual_network.main.id
}

output "control_plane_subnet_id" {
  description = "Resource ID of the control plane subnet."
  value       = azurerm_subnet.control_plane_subnet.id
}

output "control_plane_subnet_name" {
  description = "Name of the control plane subnet."
  value       = azurerm_subnet.control_plane_subnet.name
}

output "machine_subnet_id" {
  description = "Resource ID of the worker (machine) subnet."
  value       = azurerm_subnet.machine_subnet.id
}

output "machine_subnet_name" {
  description = "Name of the worker (machine) subnet."
  value       = azurerm_subnet.machine_subnet.name
}

output "network_security_group_id" {
  description = "Resource ID of the ARO network security group."
  value       = azurerm_network_security_group.aro.id
}

output "network_security_group_name" {
  description = "Name of the ARO network security group."
  value       = azurerm_network_security_group.aro.name
}

output "firewall_route_table_id" {
  description = "Resource ID of the Azure Firewall egress route table, or null when egress_traffic_restricted is false."
  value       = try(azurerm_route_table.firewall_rt[0].id, null)
}

output "firewall_route_table_name" {
  description = "Name of the Azure Firewall egress route table, or null when egress_traffic_restricted is false."
  value       = try(azurerm_route_table.firewall_rt[0].name, null)
}
