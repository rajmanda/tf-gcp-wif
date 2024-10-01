output "ca_certificate" {
  description = "The cluster ca certificate (base64 encoded)"
  value       = module.kubernetes-engine_example_autopilot_private_firewalls.ca_certificate
}

output "cluster_name" {
  description = "Cluster name"
  value       = module.kubernetes-engine_example_autopilot_private_firewalls.cluster_name
}

output "kubernetes_endpoint" {
  description = "The cluster endpoint"
  value       = module.kubernetes-engine_example_autopilot_private_firewalls.kubernetes_endpoint
}

output "location" {
  description = "The location of the cluster"
  value       = module.kubernetes-engine_example_autopilot_private_firewalls.location
}

output "master_kubernetes_version" {
  description = "Kubernetes version of the master"
  value       = module.kubernetes-engine_example_autopilot_private_firewalls.master_kubernetes_version
}

output "network_name" {
  description = "The name of the VPC being created"
  value       = module.kubernetes-engine_example_autopilot_private_firewalls.network_name
}

output "project_id" {
  description = "The project ID the cluster is in"
  value       = module.kubernetes-engine_example_autopilot_private_firewalls.project_id
}

output "region" {
  description = "The region in which the cluster resides"
  value       = module.kubernetes-engine_example_autopilot_private_firewalls.region
}

output "service_account" {
  description = "The service account to default running nodes as if not overridden in node_pools."
  value       = module.kubernetes-engine_example_autopilot_private_firewalls.service_account
}

output "subnet_names" {
  description = "The names of the subnet being created"
  value       = module.kubernetes-engine_example_autopilot_private_firewalls.subnet_names
}

output "zones" {
  description = "List of zones in which the cluster resides"
  value       = module.kubernetes-engine_example_autopilot_private_firewalls.zones
}
