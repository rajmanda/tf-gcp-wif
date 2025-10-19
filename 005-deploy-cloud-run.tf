# Deploy the application to Cloud Run
resource "google_cloud_run_v2_service" "rsvp_backend" {
  name     = var.service_name
  location = var.region
  project  = var.project_id

  # Allow public (unauthenticated) access to the service
  ingress = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.rsvp_sa.email
    containers {
      image = var.image_uri

      # Cloud Run injects the PORT environment variable automatically.
      # Your Spring Boot app must listen on this port.
      ports {
        container_port = 8080
      }

      # Mount secrets and set environment variables
      env {
        name = "GCS_BUCKET_NAME"
        value = var.gcs_bucket_name
      }
      env {
        name = "SPRING_DATA_MONGODB_URI"
        value_source {
          secret_key_ref {
            secret  = var.mongo_uri_secret_name
            version = "latest"
          }
        }
      }
      env {
        name = "SPRING_MAIL_USERNAME"
        value_source {
          secret_key_ref {
            secret  = var.gmail_user_secret_name
            version = "latest"
          }
        }
      }
      env {
        name = "SPRING_MAIL_PASSWORD"
        value_source {
          secret_key_ref {
            secret  = var.gmail_pass_secret_name
            version = "latest"
          }
        }
      }
      env {
        # This environment variable will populate the 'app.cors.allowed-origins' property in Spring Boot
        name  = "CORS_ALLOWED_ORIGINS"
        value = var.frontend_url # Use the same variable here
      }
    }
  }

  depends_on = [
    google_project_service.run_api,
    google_project_service.secretmanager_api,
    google_project_service.iam_api,
  ]
}