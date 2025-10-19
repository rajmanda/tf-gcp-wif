# Enable required APIs for the project
resource "google_project_service" "run_api" {
  service = "run.googleapis.com"
}
resource "google_project_service" "secretmanager_api" {
  service = "secretmanager.googleapis.com"
}
resource "google_project_service" "iam_api" {
  service = "iam.googleapis.com"
}
