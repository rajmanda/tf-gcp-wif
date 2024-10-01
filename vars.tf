# vars.tf
variable "project" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The region where the resources will be created"
  type        = string
}
