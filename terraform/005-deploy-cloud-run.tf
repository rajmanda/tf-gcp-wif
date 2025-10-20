# Deploy the Kalyanam Angular application to Cloud Run
resource "google_cloud_run_v2_service" "kalyanam_frontend" {
  name     = var.service_name
  location = var.region
  project  = var.project_id

  # Allow public (unauthenticated) access to the service
  ingress = "INGRESS_TRAFFIC_ALL"

  # Disable deletion protection to allow updates
  deletion_protection = false

  template {
    service_account = google_service_account.kalyanam_frontend_sa.email
    
    containers {
      image = var.image_uri

      # NGINX serves on port 80
      ports {
        container_port = 80
      }

      # Resource limits - static sites need minimal resources
      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }

      # Startup and liveness probes for health checking
      # NGINX serves the Angular app on root path
      startup_probe {
        http_get {
          path = "/"
          port = 80
        }
        initial_delay_seconds = 10
        period_seconds        = 5
        failure_threshold     = 3
      }

      liveness_probe {
        http_get {
          path = "/"
          port = 80
        }
        period_seconds    = 10
        timeout_seconds   = 5
        failure_threshold = 3
      }
    }
  }

  depends_on = [
    google_project_service.run_api,
    google_project_service.iam_api,
  ]
}
