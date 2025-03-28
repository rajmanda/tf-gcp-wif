# Get the Google client configuration for authentication
data "google_client_config" "default" {}

# Fetch details about the GKE cluster
data "google_container_cluster" "primary" {
  name     = "simple-autopilot-public-cluster"
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
  account_id   = "gcp-secret-accessor"
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
# Storage Bucket Access (Enhanced with ALL required permissions)
# -------------------------------------------------------------------

# 1. Object-level permissions
resource "google_storage_bucket_iam_member" "bucket_object_admin" {
  bucket = "shravani_kalyanam_bucket"
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.gcp_secret_accessor.email}"
}

# 2. Bucket listing permissions (fixes the 403 error)
resource "google_storage_bucket_iam_member" "bucket_legacy_reader" {
  bucket = "shravani_kalyanam_bucket"
  role   = "roles/storage.legacyBucketReader"  # Required for gsutil operations
  member = "serviceAccount:${google_service_account.gcp_secret_accessor.email}"
}

# 3. Bucket-level write permissions
resource "google_storage_bucket_iam_member" "bucket_legacy_writer" {
  bucket = "shravani_kalyanam_bucket"
  role   = "roles/storage.legacyBucketWriter"
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
# Verification Resource (NEW)
# -------------------------------------------------------------------

resource "google_service_account_key" "sa_key" {
  service_account_id = google_service_account.gcp_secret_accessor.name
}

resource "null_resource" "verify_access" {
  provisioner "local-exec" {
    command = <<-EOT
      set -e
      echo "⏳ Testing GCS access..."
      
      # Authenticate as the service account
      gcloud auth activate-service-account ${google_service_account.gcp_secret_accessor.email} \
        --key-file=<(echo '${base64decode(google_service_account_key.sa_key.private_key)}')
      
      # Test bucket listing (the operation that was failing)
      if ! gsutil ls gs://shravani_kalyanam_bucket/ >/dev/null 2>&1; then
        echo "❌ FAILED: Still getting access denied on bucket listing"
        echo "Debug info:"
        gcloud projects get-iam-policy ${data.google_client_config.default.project} \
          --flatten="bindings[].members" \
          --filter="bindings.members:${google_service_account.gcp_secret_accessor.email}" \
          --format="table(bindings.role)"
        exit 1
      fi
      
      echo "✅ Verified GCS access works!"
    EOT
    
    interpreter = ["bash", "-c"]
  }

  depends_on = [
    google_storage_bucket_iam_member.bucket_object_admin,
    google_storage_bucket_iam_member.bucket_legacy_reader,
    google_storage_bucket_iam_member.bucket_legacy_writer,
    google_project_iam_member.workload_identity_binding
  ]
}

# -------------------------------------------------------------------
# Outputs
# -------------------------------------------------------------------

output "kubernetes_service_account" {
  value = kubernetes_service_account.gke_secret_accessor.metadata[0].name
}

output "gcp_service_account" {
  value = google_service_account.gcp_secret_accessor.email
}

output "workload_identity_status" {
  value = <<EOT
Workload Identity configured between:
KSA: ${kubernetes_service_account.gke_secret_accessor.metadata[0].namespace}/${kubernetes_service_account.gke_secret_accessor.metadata[0].name}
GSA: ${google_service_account.gcp_secret_accessor.email}

Verification completed. Check Terraform outputs for any errors.
EOT
}