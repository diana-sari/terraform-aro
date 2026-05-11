output "api_server_url" {
  description = "The URL of the ARO API server."
  value       = try(azapi_resource.aro_cluster.output.properties.apiserverProfile.url, null)
}

output "console_url" {
  description = "The URL of the ARO console."
  value       = try(azapi_resource.aro_cluster.output.properties.consoleProfile.url, null)
}

output "api_server_ip" {
  description = "The IP address of the ARO API server (when present on the cluster resource)."
  value       = try(azapi_resource.aro_cluster.output.properties.apiserverProfile.ip, null)
}

output "ingress_ip" {
  description = "The IP address of the default ingress profile (when present)."
  value       = try(azapi_resource.aro_cluster.output.properties.ingressProfiles[0].ip, null)
}

output "resource_id" {
  description = "The resource ID of the ARO cluster."
  value       = azapi_resource.aro_cluster.id
}
