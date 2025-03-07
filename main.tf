# Generate a random string for the secret value
resource "random_string" "secret_value" {
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true
}
# Create the secret in Secret Manager
resource "google_secret_manager_secret" "galadb_password" {
  secret_id = "galadb_password"
  
  replication {
    auto {}
  }
}

# Add a version to the secret with the generated random string as its value
resource "google_secret_manager_secret_version" "galadb_password_version" {
  secret      = google_secret_manager_secret.galadb_password.id
  secret_data = random_string.secret_value.result
}


