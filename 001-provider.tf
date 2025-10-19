terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.7.0"
    }
  }
}
provider "google" {
  project = "properties-app-418208"
  region  = "us-central1" # Specify the desired region

}