resource "google_compute_subnetwork" "gke_subnetwork" {
  name          = "us-central1-01"
  ip_cidr_range = "10.0.0.0/16"  # Adjust this range as necessary
  region        = "us-central1"
  network       = var.network  # Ensure that var.network points to your VPC network

  secondary_ip_range {
    range_name    = "us-central1-01-gke-01-pods"
    ip_cidr_range = "10.1.0.0/16"  # Adjust this range for pods
  }

  secondary_ip_range {
    range_name    = "us-central1-01-gke-01-services"
    ip_cidr_range = "10.2.0.0/20"  # Adjust this range for services
  }
}

module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google"
  version = "33.0.4"

  # Use the variables from vars.tf
  name               = var.name
  project_id         = var.project_id
  network            = var.network
  subnetwork         = google_compute_subnetwork.gke_subnetwork.id  # Reference the created subnetwork
  ip_range_pods      = var.ip_range_pods
  ip_range_services  = var.ip_range_services

  # Pass the region explicitly
  region             = var.region

  # Optionally, you can pass zones if you have zonal clusters
  zones              = var.zones

  # Add the depends_on attribute
  depends_on = [google_compute_subnetwork.gke_subnetwork]
}
