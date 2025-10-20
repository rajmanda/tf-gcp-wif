terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.7.0"
    }
  }

  backend "gcs" {
    bucket = "tf-gcp-wif-tfstate"
    prefix = "terraform/kalyanam/state/" # Static prefix
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

