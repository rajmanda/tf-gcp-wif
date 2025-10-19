# IAM policy to allow public access to the Cloud Run service
resource "google_cloud_run_v2_service_iam_member" "noauth" {
  project  = google_cloud_run_v2_service.rsvp_backend.project
  location = google_cloud_run_v2_service.rsvp_backend.location
  name     = google_cloud_run_v2_service.rsvp_backend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}