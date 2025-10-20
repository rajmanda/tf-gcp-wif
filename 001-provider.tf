terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.7.0"
    }
  }

  backend "gcs" {
    bucket = "tf-gcp-wif-tfstate"
    prefix = "terraform/rsvpbackend/state/"  # Static prefix
  }
}