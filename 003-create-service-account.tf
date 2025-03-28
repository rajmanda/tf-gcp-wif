# Get the Google client configuration
data "google_client_config" "default" {}

# Get the GKE cluster data
data "google_container_cluster" "primary" {
  name     = "simple-autopilot-public-cluster" # Replace with your GKE cluster name
  location = "us-central1" # Adjust as needed
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
  account_id   = "gcp-secret-accessor" # Unique name for the GCP Service Account
  display_name = "GCP Secret Accessor"
}

# Grant the GCP Service Account access to Secret Manager
resource "google_secret_manager_secret_iam_member" "secret_access" {
  secret_id  = "galadb_password" # Replace with your secret ID
  role       = "roles/secretmanager.secretAccessor"
  member     = "serviceAccount:${google_service_account.gcp_secret_accessor.email}"
}

# Grant the GCP Service Account access to Cloud Storage (Viewer)
resource "google_project_iam_member" "storage_view_access" {
  project = "properties-app-418208" # Use your actual project ID
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.gcp_secret_accessor.email}"
}

# Grant the GCP Service Account permission to create objects in Cloud Storage
resource "google_project_iam_member" "storage_create_access" {
  project = "properties-app-418208" # Use your actual project ID
  role    = "roles/storage.objectCreator"
  member  = "serviceAccount:${google_service_account.gcp_secret_accessor.email}"
}

# Create a Kubernetes Service Account
resource "kubernetes_service_account" "gke_secret_accessor" {
  metadata {
    name      = "gke-secret-accessor" # Unique name for the Kubernetes Service Account
    namespace = "kalyanam"
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.gcp_secret_accessor.email
    }
  }
}

# Create IAM Policy Binding between Kubernetes Service Account and GCP Service Account
resource "google_project_iam_member" "k8s_sa_to_gcp_sa" {
  project = "properties-app-418208" # Use your actual project ID
  role    = "roles/iam.serviceAccountTokenCreator"
  member  = "serviceAccount:properties-app-418208.svc.id.goog[kalyanam/gke-secret-accessor]"
}

# IAM Role Binding for the Kubernetes Service Account to impersonate the GCP Service Account
resource "google_project_iam_binding" "gke_sa_to_secret_accessor" {
  project = "properties-app-418208" # Use your actual project ID
  role    = "roles/secretmanager.secretAccessor"
  members = [
    "serviceAccount:${google_service_account.gcp_secret_accessor.email}"
  ]
}



/*
 * Some debug scripts
Step 1: List IAM Policy Bindings for the Service Account
Run the following command to see all roles assigned to the service account:

sh
Copy
Edit
gcloud projects get-iam-policy properties-app-418208 \
  --flatten="bindings[].members" \
  --format="table(bindings.role)" \
  --filter="bindings.members:serviceAccount:gcp-secret-accessor@properties-app-418208.iam.gserviceaccount.com"

  gcloud secrets get-iam-policy galadb_password --project=properties-app-418208
  gcloud storage buckets list --project=properties-app-418208 | grep kalyanam
  gcloud storage buckets get-iam-policy gs://shravani_kalyanam_bucket --project=properties-app-418208
*/
