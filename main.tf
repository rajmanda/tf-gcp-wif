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

  project_id = var.project
  region  = var.region
}


