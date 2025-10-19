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

output "secret_ids" {
  description = "The IDs of the created secrets in Secret Manager."
  value = {
    mongodb_uri    = google_secret_manager_secret.mongodb_uri.secret_id
    gmail_username = google_secret_manager_secret.gmail_username.secret_id
    gmail_password = google_secret_manager_secret.gmail_password.secret_id
  }
}

output "next_steps" {
  description = "Next steps after deployment"
  value = <<-EOT
  
  ========================================
  🎉 Deployment Successful!
  ========================================
  
  Your backend is deployed at: ${google_cloud_run_v2_service.rsvp_backend.uri}
  
  NEXT STEPS:
  
  1. Test your backend:
     curl ${google_cloud_run_v2_service.rsvp_backend.uri}/actuator/health
  
  2. View logs:
     gcloud run services logs tail rsvp-backend --region=${var.region}
  
  3. Update secret values (if needed):
     ./add-secret-values.sh
  
  4. Update your frontend to use this backend URL
  
  ========================================
  EOT
}