# Create a dedicated service account for the Cloud Run service
resource "google_service_account" "kalyanam_frontend_sa" {
  account_id   = "${var.service_name}-sa"
  display_name = "Service Account for Kalyanam Frontend"
  project      = var.project_id
}
