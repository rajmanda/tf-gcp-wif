# Enable Cloud Run API
resource "google_project_service" "run_api" {
  project = var.project_id
  service = "run.googleapis.com"

  # Don't disable the API on destroy to avoid breaking other services
  disable_on_destroy = false
}

# Enable IAM API
resource "google_project_service" "iam_api" {
  project = var.project_id
  service = "iam.googleapis.com"

  disable_on_destroy = false
}
