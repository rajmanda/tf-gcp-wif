terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 3.33.0, < 6.2.0"  # Adjust this as needed
    }
  }
}

provider "google" {
  project = var.project
  region  = var.region
}

