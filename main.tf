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

module "kubernetes-engine_example_autopilot_private_firewalls" {
  source  = "terraform-google-modules/kubernetes-engine/google//examples/autopilot_private_firewalls"
  version = "33.0.4"

  project_id = var.project
  region     = var.region
}

# Assign IAM roles to the dynamically created service account
resource "google_project_iam_member" "cluster_service_account_roles" {
  for_each = toset([
    "roles/iam.serviceAccountAdmin",
    "roles/container.clusterAdmin",
    "roles/monitoring.metricWriter",
    "roles/stackdriver.resourceMetadata.writer"
  ])

  project = var.project
  role    = each.key
  member  = "serviceAccount:${module.kubernetes-engine_example_autopilot_private_firewalls.service_account}"
}
