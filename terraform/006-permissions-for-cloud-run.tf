# Allow unauthenticated (public) access to the Cloud Run service
resource "google_cloud_run_v2_service_iam_member" "public_access" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.kalyanam_frontend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
