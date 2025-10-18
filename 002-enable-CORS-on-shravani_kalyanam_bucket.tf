resource "google_storage_bucket" "shravani" {
  name     = "kalyanam_bucket"
  location = "US"

  cors {
    origin          = ["http://localhost:4200"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE", "OPTIONS"]
    response_header = ["Content-Type", "x-goog-resumable", "Range", "Accept", "Authorization", "x-goog-meta-*"]
    max_age_seconds = 3600
  }

  versioning {
    enabled = true
  }
}