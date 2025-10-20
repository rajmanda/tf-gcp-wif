resource "google_storage_bucket" "shravani" {
  name     = var.gcs_bucket_name
  location = "US"
  # Allow Terraform to delete the bucket even if it contains objects
  force_destroy = true

  cors {
    origin          = split(",", var.frontend_url) # Split comma-separated string into list
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE", "OPTIONS"]
    response_header = ["Content-Type", "x-goog-resumable", "Range", "Accept", "Authorization", "x-goog-meta-*"]
    max_age_seconds = 3600
  }

  versioning {
    enabled = true
  }
}