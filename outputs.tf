output "service_url" {
  description = "The URL of the deployed Cloud Run service."
  value       = google_cloud_run_v2_service.rsvp_backend.uri
}

output "gcs_bucket_name" {
  description = "The name of the GCS bucket for file uploads."
  value       = google_storage_bucket.shravani.name
}

output "gcs_bucket_url" {
  description = "The self-link URL of the GCS bucket."
  value       = google_storage_bucket.shravani.url
}

output "service_account_email" {
  description = "The email of the service account used by Cloud Run."
  value       = google_service_account.rsvp_sa.email
}