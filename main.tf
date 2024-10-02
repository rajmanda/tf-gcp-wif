resource "google_storage_bucket" "my-tf-gcp-wif-bucket-01" {
  name                        = "tf-gcp-wif-001"
  location                    = "us-east1"
  force_destroy               = true
  public_access_prevention    = "enforced"
}

resource "google_storage_bucket" "my-tf-gcp-wif-bucket-02" {
  name                        = "tf-gcp-wif-002"
  location                    = "us-east1"
  force_destroy               = true
  public_access_prevention    = "enforced"
}

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
