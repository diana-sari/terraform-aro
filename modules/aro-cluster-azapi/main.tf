locals {
  outbound_type = coalesce(
    var.outbound_type,
    var.api_server_visibility == "Public" ? "Loadbalancer" : "UserDefinedRouting"
  )
}

resource "azapi_resource" "aro_cluster" {
  type                      = "Microsoft.RedHatOpenShift/openShiftClusters@2025-07-25"
  schema_validation_enabled = true
  response_export_values    = ["properties.apiserverProfile", "properties.consoleProfile", "properties.clusterProfile", "properties.ingressProfiles"]
  name                      = var.cluster_name
  location                  = var.location
  parent_id                 = "/subscriptions/${split("/", var.control_plane_subnet_id)[2]}/resourceGroups/${var.resource_group_name}"
  tags                      = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [var.cluster_msi_resource_id]
  }

  body = {
    properties = {
      clusterProfile = {
        domain               = var.domain
        resourceGroupId      = "/subscriptions/${split("/", var.control_plane_subnet_id)[2]}/resourceGroups/${var.managed_resource_group_name}"
        pullSecret           = var.pull_secret
        version              = var.aro_version
        fipsValidatedModules = "Disabled"
      }
      masterProfile = {
        vmSize           = var.control_plane_vm_size
        subnetId         = var.control_plane_subnet_id
        encryptionAtHost = var.encryption_at_host ? "Enabled" : "Disabled"
      }
      workerProfiles = [
        {
          name             = "worker"
          vmSize           = var.compute_vm_size
          diskSizeGB       = var.compute_vm_disk_size
          subnetId         = var.compute_subnet_id
          count            = var.compute_node_count
          encryptionAtHost = var.encryption_at_host ? "Enabled" : "Disabled"
        }
      ]
      networkProfile = {
        podCidr          = var.pod_cidr
        serviceCidr      = var.service_cidr
        outboundType     = local.outbound_type
        preconfiguredNSG = var.preconfigured_nsg
      }
      apiserverProfile = {
        visibility = var.api_server_visibility
      }
      ingressProfiles = [
        {
          name       = "default"
          visibility = var.ingress_visibility
        }
      ]
      platformWorkloadIdentityProfile = {
        platformWorkloadIdentities = {
          for k, v in var.platform_workload_identities : k => {
            resourceId = v
          }
        }
      }
    }
  }

  retry = {
    error_message_regex  = ["RetryableError", "ReferencedResourceNotProvisioned", "InvalidLinkedSubnet"]
    interval_seconds     = 30
    max_interval_seconds = 180
  }

  lifecycle {
    ignore_changes = [
      body,
      tags,
      timeouts,
      type,
      response_export_values,
    ]
  }

  timeouts {
    create = try(coalesce(var.timeouts.create, "90m"), "90m")
    delete = try(coalesce(var.timeouts.delete, "60m"), "60m")
  }
}
