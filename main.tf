resource "google_compute_network" "vpc_network" {
  name                    = "vpc-01"
  auto_create_subnetworks = false  # Set to false if you are creating custom subnetworks
}

resource "google_compute_subnetwork" "gke_subnetwork" {
  name          = "us-central1-01"
  ip_cidr_range = "10.0.0.0/16"  # Adjust this range as necessary
  region        = var.region
  network       = google_compute_network.vpc_network.id  # Reference the created VPC network

  secondary_ip_range {
    range_name    = "us-central1-01-gke-01-pods"
    ip_cidr_range = "10.1.0.0/16"  # Adjust this range for pods
  }

  secondary_ip_range {
    range_name    = "us-central1-01-gke-01-services"
    ip_cidr_range = "10.2.0.0/20"  # Adjust this range for services
  }

  depends_on = [google_compute_network.vpc_network]  # Ensure the network is created before the subnetwork
}

module "gke" {
  source  = "terraform-google-modules/kubernetes-engine/google"
  version = "33.0.4"

  # Use the variables from vars.tf
  name               = var.name
  project_id         = var.project_id
  network            = google_compute_network.vpc_network.name  # Reference the created VPC network name
  subnetwork         = google_compute_subnetwork.gke_subnetwork.name  # Reference the created subnetwork name
  ip_range_pods      = var.ip_range_pods
  ip_range_services  = var.ip_range_services

  # Pass the region explicitly
  region             = var.region

  # Optionally, you can pass zones if you have zonal clusters
  zones              = var.zones

  # Disable deletion protection
  deletion_protection = false  
  
  depends_on = [google_compute_subnetwork.gke_subnetwork]  # Ensure the subnetwork is created before GKE
}

