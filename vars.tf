variable "name" {
  description = "The name of the cluster (required)"
  type        = string
}

variable "project_id" {
  description = "The project ID to host the cluster in (required)"
  type        = string
}

variable "network" {
  description = "The VPC network to host the cluster in (required)"
  type        = string
}

variable "subnetwork" {
  description = "The subnetwork to host the cluster in (required)"
  type        = string
}

variable "ip_range_pods" {
  description = "The name of the secondary subnet IP range to use for pods"
  type        = string
}

variable "ip_range_services" {
  description = "The name of the secondary subnet range to use for services"
  type        = string
}


variable "project_id" {
  description = "The ID of the GCP project."
  type        = string
}

variable "region" {
  description = "The region to deploy the GKE cluster."
  type        = string
}

variable "zones" {
  description = "The availability zones for the GKE cluster."
  type        = list(string)
}

variable "network" {
  description = "The VPC network to use for the GKE cluster."
  type        = string
}

variable "subnetwork" {
  description = "The subnetwork to use for the GKE cluster."
  type        = string
}

variable "ip_range_pods" {
  description = "The IP range for Pods."
  type        = string
}

variable "ip_range_services" {
  description = "The IP range for Services."
  type        = string
}

variable "service_account" {
  description = "The service account to associate with the GKE node pool."
  type        = string
}

variable "node_pools" {
  description = "Configuration for node pools."
  type = list(object({
    name                        = string
    machine_type                = string
    node_locations              = string
    min_count                   = number
    max_count                   = number
    local_ssd_count             = number
    spot                        = bool
    disk_size_gb                = number
    disk_type                   = string
    image_type                  = string
    enable_gcfs                 = bool
    enable_gvnic                = bool
    logging_variant             = string
    auto_repair                 = bool
    auto_upgrade                = bool
    initial_node_count          = number
    accelerator_count           = number
    accelerator_type            = string
    gpu_driver_version          = string
    gpu_sharing_strategy        = string
    max_shared_clients_per_gpu  = number
  }))
}

