# Create a dedicated service account for the Cloud Run service
resource "google_service_account" "rsvp_sa" {
  account_id   = "${var.service_name}-sa"
  display_name = "Service Account for RSVP Backend"
}