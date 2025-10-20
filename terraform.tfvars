project_id      = "properties-app-418208"
region          = "us-central1"
image_uri       = "docker.io/dockerrajmanda/rsvpbackend:133"
gcs_bucket_name = "kalyanam_bucket_2025"

frontend_url = <<EOT
http://localhost:4200,
https://staging.kalyanam.com,
https://www.kalyanam.com,
https://www.rajmanda-dev.com,
https://kalyanam-frontend-175415323680.us-central1.run.app
EOT
