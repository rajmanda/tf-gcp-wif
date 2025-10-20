# Create a dedicated service account for the Cloud Run service
resource "google_service_account" "rsvp_sa" {
  account_id   = "${var.service_name}-sa"
  display_name = "Service Account for RSVP Backend"
}

# Dedicated GCS Signer Service Account
resource "google_service_account" "gcs_signer_sa" {
  account_id   = "gcs-signer-sa"
  display_name = "GCS Signed URL Creator"
}

# 1. Allow the Runtime SA to read ALL secrets in the project
resource "google_project_iam_member" "rsvp_sa_all_secrets" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.rsvp_sa.email}"

  depends_on = [
    google_service_account.rsvp_sa
  ]
}

# 2. Allow the Runtime SA to access the GCS bucket
resource "google_storage_bucket_iam_member" "bucket_access_admin" {
  bucket = google_storage_bucket.shravani.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.rsvp_sa.email}"

  depends_on = [
    google_storage_bucket.shravani,
    google_service_account.rsvp_sa
  ]
}

# 3. Allow the signer SA to access the GCS bucket (for signing URLs)
resource "google_storage_bucket_iam_member" "gcs_signer_sa_bucket_access" {
  bucket = google_storage_bucket.shravani.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.gcs_signer_sa.email}"

  depends_on = [
    google_storage_bucket.shravani,
    google_service_account.gcs_signer_sa
  ]
}

# 4. Allow rsvp_sa to impersonate the signer SA
resource "google_service_account_iam_member" "signer_impersonator" {
  service_account_id = google_service_account.gcs_signer_sa.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "serviceAccount:${google_service_account.rsvp_sa.email}"

  depends_on = [
    google_service_account.gcs_signer_sa,
    google_service_account.rsvp_sa
  ]
}

# 5. CRITICAL: Give the SIGNER SA ability to sign keys
# (required to actually sign the URLs)
resource "google_project_iam_member" "signer_keyadmin" {
  project = var.project_id
  role    = "roles/iam.serviceAccountKeyAdmin"
  member  = "serviceAccount:${google_service_account.gcs_signer_sa.email}"

  depends_on = [
    google_service_account.gcs_signer_sa
  ]
}

// Needed for running this locally: allow user to impersonate the GCS Signer SA
resource "google_service_account_iam_member" "rajmanda_as_gcs_signer" {
  service_account_id = google_service_account.gcs_signer_sa.name
  role               = "roles/iam.serviceAccountTokenCreator"
  member             = "user:raj.manda@gmail.com"
}
