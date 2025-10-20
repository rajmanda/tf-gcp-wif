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

# 1. Allow the Runtime SA to read secrets
resource "google_project_iam_member" "rsvp_sa_all_secrets" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.rsvp_sa.email}"

  depends_on = [
    google_service_account.rsvp_sa
  ]
}

# ... (add other secret accessor bindings for gmail user/pass) ...

# 2. Allow the Runtime SA to access the GCS bucket (e.g., to check if a blob exists)
resource "google_storage_bucket_iam_member" "bucket_access_admin" {
  bucket = google_storage_bucket.shravani.name
  role   = "roles/storage.objectAdmin" # Or a more restrictive role if it only needs to read
  member = "serviceAccount:${google_service_account.rsvp_sa.email}"

  depends_on = [
    google_storage_bucket.shravani,
    google_service_account.rsvp_sa
  ]
}

# 3. CRITICAL: Allow the Runtime SA to impersonate the Signer SA
resource "google_service_account_iam_member" "signer_impersonator" {
  # The resource is the Signer SA
  service_account_id = google_service_account.gcs_signer_sa.name
  
  # The role that allows signing
  role               = "roles/iam.serviceAccountTokenCreator"

  # The member being granted permission is the Runtime SA
  member             = "serviceAccount:${google_service_account.rsvp_sa.email}"

  depends_on = [
    google_service_account.gcs_signer_sa,
    google_service_account.rsvp_sa
  ]
}

# ### Service Accounts - SUMMARY 

# - rsvp_sa (Cloud Run runtime SA)
# - gcs_signer_sa (Dedicated signing SA)

# ### Secret Manager Access
# - rsvp_sa with secretAccessor role for necessary secrets

# ### GCS Bucket Access
# - Both service accounts have appropriate storage.objectAdmin roles

# ### Impersonation & Signing
# - rsvp_sa can impersonate gcs_signer_sa to sign URLs