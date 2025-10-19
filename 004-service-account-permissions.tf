

# Grant the service account permission to access secrets
resource "google_secret_manager_secret_iam_member" "mongo_uri_accessor" {
  project   = var.project_id
  secret_id = var.mongo_uri_secret_name
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.rsvp_sa.email}"
}

resource "google_secret_manager_secret_iam_member" "gmail_user_accessor" {
  project   = var.project_id
  secret_id = var.gmail_user_secret_name
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.rsvp_sa.email}"
}

resource "google_secret_manager_secret_iam_member" "gmail_pass_accessor" {
  project   = var.project_id
  secret_id = var.gmail_pass_secret_name
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.rsvp_sa.email}"
}

# Grant the service account permission to read/write to the GCS bucket
resource "google_storage_bucket_iam_member" "gcs_bucket_access" {
  bucket = var.gcs_bucket_name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.rsvp_sa.email}"
}
