# Generate a random string for the secret value
resource "random_string" "secret_value_1" {
  length  = 16
  special = true
  upper   = true
  lower   = true
  numeric = true
}
# Create the secret in Secret Manager
resource "google_secret_manager_secret" "gmail_password" {
  secret_id = "gmail_password"
  
  replication {
    auto {}
  }
}

# Add a version to the secret with the generated random string as its value
resource "google_secret_manager_secret_version" "gmail_password_version" {
  secret      = google_secret_manager_secret.gmail_password.id
  secret_data = random_string.secret_value_1.result
}