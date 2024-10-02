module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google"
  version = "33.0.4"
  
  # Use the variables from vars.tf
  name               = var.name
  project_id         = var.project_id
  network            = var.network
  subnetwork         = var.subnetwork
  ip_range_pods      = var.ip_range_pods
  ip_range_services  = var.ip_range_services
}

