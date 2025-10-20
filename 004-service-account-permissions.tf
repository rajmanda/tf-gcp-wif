# resource "google_service_account" "rsvp_sa" {
#   account_id   = "${var.service_name}-sa"
#   display_name = "Service Account for RSVP Backend"
# }

# Grant the service account permission to access secrets
resource "google_secret_manager_secret_iam_member" "mongo_uri_accessor" {
  project   = var.project_id
  secret_id = var.mongo_uri_secret_name
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.rsvp_sa.email}"

  depends_on = [
    google_secret_manager_secret.mongodb_uri
  ]
}

resource "google_secret_manager_secret_iam_member" "gmail_user_accessor" {
  project   = var.project_id
  secret_id = var.gmail_user_secret_name
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.rsvp_sa.email}"

  depends_on = [
    google_secret_manager_secret.gmail_username
  ]
}

resource "google_secret_manager_secret_iam_member" "gmail_pass_accessor" {
  project   = var.project_id
  secret_id = var.gmail_pass_secret_name
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.rsvp_sa.email}"

  depends_on = [
    google_secret_manager_secret.gmail_password
  ]
}

# Grant the service account permission to read/write to the GCS bucket
resource "google_storage_bucket_iam_member" "gcs_bucket_access" {
  bucket = var.gcs_bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.rsvp_sa.email}"

  depends_on = [
    google_storage_bucket.shravani
  ]
}

# ============================================
# IAM Permissions - Service Account Impersonation
# ============================================

# Grant the Cloud Run SA (rsvp_sa) permission to impersonate the Signer SA
# This allows rsvp_sa to generate signed URLs using gcs_signer_sa
resource "google_service_account_iam_member" "signer_impersonator" {
  service_account_id = google_service_account.gcs_signer_sa.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.rsvp_sa.email}"

  depends_on = [
    google_service_account.rsvp_sa,
    google_service_account.gcs_signer_sa
  ]
}

