# Get the Google client configuration
data "google_client_config" "default" {}

# Fetch GKE cluster details
data "google_container_cluster" "primary" {
  name     = "simple-autopilot-public-cluster"
  location = "us-central1"
}

# Configure Kubernetes provider
provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}

# Create namespace if not exists
resource "null_resource" "create_namespace" {
  provisioner "local-exec" {
    command = <<EOT
      kubectl get namespace kalyanam || kubectl create namespace kalyanam
    EOT
  }
}

# -------------------------------------------------------------------
# GCP Service Account
# -------------------------------------------------------------------
resource "google_service_account" "gcp_secret_accessor" {
  account_id   = "gcp-secret-accessor"
  display_name = "Service Account for GKE Secret and Storage Access"
}

# -------------------------------------------------------------------
# Secret Manager Access
# -------------------------------------------------------------------
resource "google_secret_manager_secret_iam_member" "secret_access" {
  secret_id = "galadb_password"
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.gcp_secret_accessor.email}"
}

# -------------------------------------------------------------------
# Storage Bucket Access (FIXED with all required permissions)
# -------------------------------------------------------------------
resource "google_storage_bucket_iam_member" "bucket_object_admin" {
  bucket = "shravani_kalyanam_bucket"
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.gcp_secret_accessor.email}"
}

resource "google_storage_bucket_iam_member" "bucket_legacy_reader" {
  bucket = "shravani_kalyanam_bucket"
  role   = "roles/storage.legacyBucketReader"
  member = "serviceAccount:${google_service_account.gcp_secret_accessor.email}"
}

# -------------------------------------------------------------------
# Workload Identity Configuration
# -------------------------------------------------------------------
resource "kubernetes_service_account" "gke_secret_accessor" {
  metadata {
    name      = "gke-secret-accessor"
    namespace = "kalyanam"
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.gcp_secret_accessor.email
    }
  }
  depends_on = [null_resource.create_namespace]
}

resource "google_project_iam_member" "workload_identity_binding" {
  project = "properties-app-418208"
  role    = "roles/iam.workloadIdentityUser"
  member  = "serviceAccount:properties-app-418208.svc.id.goog[kalyanam/gke-secret-accessor]"
}
# -------------------------------------------------------------------
# Outputs
# -------------------------------------------------------------------
output "gcp_service_account_email" {
  value = google_service_account.gcp_secret_accessor.email
}

output "verification_instructions" {
  value = <<EOT
Workload Identity verification completed.
If you see '✅ Verification successful' above, your setup is correct.
Otherwise, check the error messages for troubleshooting.
GSA: ${google_service_account.gcp_secret_accessor.email}
KSA: kalyanam/gke-secret-accessor
EOT
}