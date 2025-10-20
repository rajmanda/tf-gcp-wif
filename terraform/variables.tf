variable "project_id" {
  description = "The GCP project ID to deploy to."
  type        = string
}

variable "region" {
  description = "The GCP region to deploy the service in."
  type        = string
  default     = "us-central1"
}

variable "service_name" {
  description = "The name of the Cloud Run service."
  type        = string
  default     = "kalyanam-frontend"
}

variable "image_uri" {
  description = "The full URI of the container image (Docker Hub or Artifact Registry)."
  type        = string
}
