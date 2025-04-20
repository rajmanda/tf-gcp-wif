terraform {
  backend "gcs" {
    bucket  = "tf-gcp-wif-tfstate"
    prefix  = "terraform/state"   # Optional, used for organization within the bucket
  }
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.16.1" # Check for the latest version
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.33.0"
    }
  }
}

provider "google" {
  project = "properties-app-418208"
  region  = "us-central1" # Specify the desired region
}



output "kubernetes_cluster_endpoint" {
  value = data.google_container_cluster.primary.endpoint
}

# Get the Google client configuration
data "google_client_config" "default" {}

# Get the GKE cluster data
data "google_container_cluster" "primary" {
  name     = "simple-autopilot-public-cluster"  # Replace with your GKE cluster name
  location = "us-central1"  # Adjust as needed
}

provider "kubernetes" {
  #host                   = "https://${module.kubernetes-engine_example_simple_autopilot_public.kubernetes_endpoint}"
  host                   = "https://${data.google_container_cluster.primary.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
}

# Define the Helm provider
provider "helm" {
  kubernetes {
    #host                   = "https://${module.kubernetes-engine_example_simple_autopilot_public.kubernetes_endpoint}"
    host                   = "https://${data.google_container_cluster.primary.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(data.google_container_cluster.primary.master_auth[0].cluster_ca_certificate)
  }
}
