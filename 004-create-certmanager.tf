# Data block to refer to the existing GKE cluster
data "google_container_cluster" "existing" {
  name     = "simple-autopilot-public-cluster"  # Replace with your GKE cluster name
  location = "us-central1"                      # Replace with your cluster location
}

# cert-manager service account does not have the necessary permissions to create a leader election record in the kube-system namespace - hence creating this namespace.
resource "kubernetes_namespace" "cert-manager-leader-election" {
  #depends_on = [module.kubernetes-engine_example_simple_autopilot_public]
  depends_on = [ data.google_container_cluster.existing ]
  metadata {
    name = "cert-manager-leader-election"
  }
}

resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.12.0"  # Specify the desired chart version
  namespace  = "cert-manager"

  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }
  set {
    name  = "extraArgs[0]"
    value = "--leader-election-namespace=cert-manager-leader-election"
  }
}
