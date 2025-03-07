terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "6.24.0"
    }
  }
}
provider "google" {
   project = "properties-app-418208"
  region  = "us-east1" # Specify the desired region
}