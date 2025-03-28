# Configure the Google Cloud provider
provider "google" {
  project = "properties-app-418208"  # Replace with your project ID
  region  = "us-central1"
}

# Get the Google client configuration for authentication
data "google_client_config" "default" {}

# Fetch details about the GKE cluster
data "google_container_cluster" "primary" {
  name     = "simple-autopilot-public-cluster"  # Your GKE cluster name
  location = "us-central1"
}

# Configure the Kubernetes provider
provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}

# Create the Kubernetes namespace if it doesn't exist
resource "null_resource" "create_namespace" {
  provisioner "local-exec" {
    command = <<EOT
      kubectl get namespace kalyanam || kubectl create namespace kalyanam
    EOT
  }
}

# -------------------------------------------------------------------
# GCP Service Account Configuration
# -------------------------------------------------------------------

# Create the GCP Service Account that will access secrets and storage
resource "google_service_account" "gcp_secret_accessor" {
  account_id   = "gcp-secret-accessor"  # Unique identifier
  display_name = "Service Account for GKE Secret and Storage Access"
}

# -------------------------------------------------------------------
# Secret Manager Access
# -------------------------------------------------------------------

# Grant access to the specific MongoDB password secret
resource "google_secret_manager_secret_iam_member" "secret_access" {
  secret_id = "galadb_password"  # Your MongoDB password secret name
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.gcp_secret_accessor.email}"
}

# -------------------------------------------------------------------
# Storage Bucket Access
# -------------------------------------------------------------------

# Grant full object management permissions (create/update/delete)
resource "google_storage_bucket_iam_member" "bucket_admin_access" {
  bucket = "shravani_kalyanam_bucket"  # Your backup bucket
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.gcp_secret_accessor.email}"
}

# Grant object listing permissions (required for gsutil operations)
resource "google_storage_bucket_iam_member" "bucket_list_access" {
  bucket = "shravani_kalyanam_bucket"
  role   = "roles/storage.objectViewer"  # Includes storage.objects.list
  member = "serviceAccount:${google_service_account.gcp_secret_accessor.email}"
}

# -------------------------------------------------------------------
# Workload Identity Configuration
# -------------------------------------------------------------------

# Create the Kubernetes Service Account
resource "kubernetes_service_account" "gke_secret_accessor" {
  metadata {
    name      = "gke-secret-accessor"
    namespace = "kalyanam"
    annotations = {
      # Critical: Links KSA to GSA via Workload Identity
      "iam.gke.io/gcp-service-account" = google_service_account.gcp_secret_accessor.email
    }
  }

  depends_on = [null_resource.create_namespace]
}

# Allow Kubernetes SA to impersonate the GCP SA
resource "google_project_iam_member" "workload_identity_binding" {
  project = "properties-app-418208"
  role    = "roles/iam.workloadIdentityUser"
  member  = "serviceAccount:properties-app-418208.svc.id.goog[kalyanam/gke-secret-accessor]"
}

# Grant token creator role to allow impersonation
resource "google_project_iam_member" "token_creator" {
  project = "properties-app-418208"
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:${google_service_account.gcp_secret_accessor.email}"
}

# -------------------------------------------------------------------
# Output Useful Information
# -------------------------------------------------------------------

output "kubernetes_service_account" {
  value = kubernetes_service_account.gke_secret_accessor.metadata[0].name
}

output "gcp_service_account" {
  value = google_service_account.gcp_secret_accessor.email
}

output "workload_identity_setup_command" {
  value = <<EOT
  Workload Identity is now configured. Verify with:
  kubectl describe serviceaccount ${kubernetes_service_account.gke_secret_accessor.metadata[0].name} -n ${kubernetes_service_account.gke_secret_accessor.metadata[0].namespace}
  EOT
}