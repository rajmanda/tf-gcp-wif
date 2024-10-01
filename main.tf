resource "google_storage_bucket" "my-tf-gcp-wif-bucket-01" {
  name          = "tf-gcp-wif-001"
  location      = "us-east1"
  force_destroy = true
  public_access_prevention = "enforced"
}

resource "google_storage_bucket" "my-tf-gcp-wif-bucket-02" {
  name          = "tf-gcp-wif-002"
  location      = "us-east1"
  force_destroy = true
  public_access_prevention = "enforced"
}

module "kubernetes-engine_example_autopilot_private_firewalls" {
  source  = "terraform-google-modules/kubernetes-engine/google//examples/autopilot_private_firewalls"
  version = "33.0.4"

  project_id = var.project_id
  region     = var.region
}

# Outputs
output "ca_certificate" {
  description = "The cluster CA certificate (base64 encoded)"
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
  description = "Location of the cluster"
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
  value       = var.project_id
}

output "region" {
  description = "The region in which the cluster resides"
  value       = var.region
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


