# Get the Google client configuration
data "google_client_config" "default" {}

# Get the GKE cluster data
data "google_container_cluster" "primary" {
  name     = "simple-autopilot-public-cluster"  # Replace with your GKE cluster name
  location = "us-central1"  # Adjust as needed
}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}

resource "null_resource" "create_namespace" {
  provisioner "local-exec" {
    command = <<EOT
    kubectl get namespace kalyanam || kubectl create namespace kalyanam
    EOT
  }
}


#########
# Create a GCP Service Account
resource "google_service_account" "gcp_secret_accessor" {
  account_id   = "gcp-secret-accessor"  # Unique name for the GCP Service Account
  display_name = "GCP Secret Accessor"
}

# Grant the GCP Service Account access to Secret Manager
resource "google_secret_manager_secret_iam_member" "secret_access" {
  secret_id = "galadb_password"  # Replace with your secret ID
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.gcp_secret_accessor.email}"
}

# Create a Kubernetes Service Account
resource "kubernetes_service_account" "gke_secret_accessor" {
  metadata {
    name      = "gke-secret-accessor"  # Unique name for the Kubernetes Service Account
    namespace = "kalyanam"
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.gcp_secret_accessor.email
    }
  }
}
