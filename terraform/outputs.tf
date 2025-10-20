output "service_url" {
  description = "The URL of the deployed Cloud Run service"
  value       = google_cloud_run_v2_service.kalyanam_frontend.uri
}

output "service_name" {
  description = "The name of the Cloud Run service"
  value       = google_cloud_run_v2_service.kalyanam_frontend.name
}

output "service_account_email" {
  description = "The email of the service account used by Cloud Run"
  value       = google_service_account.kalyanam_frontend_sa.email
}

output "region" {
  description = "The region where the service is deployed"
  value       = var.region
}
