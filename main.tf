module "kubernetes-engine" {
  source  = "terraform-google-modules/kubernetes-engine/google"
  version = "33.0.4"

  # Required inputs
  ip_range_pods      = var.ip_range_pods
  ip_range_services  = var.ip_range_services
  name               = var.name
  network            = var.network
  project_id         = var.project_id
  subnetwork         = var.subnetwork
}
