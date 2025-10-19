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
  default     = "rsvp-backend"
}

variable "image_uri" {
  description = "The full URI of the container image in Artifact Registry."
  type        = string
}

variable "gcs_bucket_name" {
  description = "The name of the GCS bucket for file uploads."
  type        = string
}

variable "mongo_uri_secret_name" {
  description = "The name of the secret in Secret Manager for the MongoDB URI."
  type        = string
  default     = "mongodb-uri"
}

variable "gmail_user_secret_name" {
  description = "The name of the secret in Secret Manager for the Gmail username."
  type        = string
  default     = "gmail-username"
}

variable "gmail_pass_secret_name" {
  description = "The name of the secret in Secret Manager for the Gmail password."
  type        = string
  default     = "gmail-password"
}

variable "frontend_url" {
  description = "The base URL of the frontend application for CORS. Can be a comma-separated list for multiple origins."
  type        = string
  # Default to a common local development URL (e.g., for Angular).
  # This will be used if no value is provided in a .tfvars file.
  default     = "http://localhost:4200"
}