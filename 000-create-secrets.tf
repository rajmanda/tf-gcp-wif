# Create secrets in Secret Manager
# Note: This creates empty secrets. You must add versions with actual values.

resource "google_secret_manager_secret" "mongodb_uri" {
  secret_id = var.mongo_uri_secret_name
  project   = var.project_id

  replication {
    auto {}
  }

  depends_on = [
    google_project_service.secretmanager_api
  ]
}

resource "google_secret_manager_secret" "gmail_username" {
  secret_id = var.gmail_user_secret_name
  project   = var.project_id

  replication {
    auto {}
  }

  depends_on = [
    google_project_service.secretmanager_api
  ]
}

resource "google_secret_manager_secret" "gmail_password" {
  secret_id = var.gmail_pass_secret_name
  project   = var.project_id

  replication {
    auto {}
  }

  depends_on = [
    google_project_service.secretmanager_api
  ]
}
