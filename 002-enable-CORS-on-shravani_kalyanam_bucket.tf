resource "google_storage_bucket_cors_configuration" "shravani_cors" {
  bucket = "shravani_kalyanam_bucket"

  cors {
    origin          = ["http://localhost:4200"]
    method          = ["GET", "HEAD", "PUT", "POST", "DELETE", "OPTIONS"]
    response_header = ["Content-Type", "x-goog-resumable", "Range", "Accept", "Authorization", "x-goog-meta-*"]
    max_age_seconds = 3600
  }
}
