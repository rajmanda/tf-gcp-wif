# Get the Google client configuration
data "google_client_config" "default" {}

# Get the GKE cluster data
data "google_container_cluster" "gke_cluster" {
  depends_on = [ google_container_node_pool.primary_nodes ]
  name     = "gke-cluster"    # Your cluster name
  location = "us-central1-a"  # Cluster location
}

# Define the Kubernetes provider
provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.gke_cluster.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.gke_cluster.master_auth.0.cluster_ca_certificate)
}

# Define the Helm provider
provider "helm" {
  kubernetes {
    host                   = "https://${data.google_container_cluster.gke_cluster.endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(data.google_container_cluster.gke_cluster.master_auth.0.cluster_ca_certificate)
  }
}

# Deploy resources on GKE
resource "kubernetes_namespace" "nginxns" {
  depends_on = [ google_container_node_pool.primary_nodes ]
  metadata {
    name = "ingress-nginx"
  }
}

# # Deploy the NGINX Ingress Controller using Helm
# resource "helm_release" "nginx_ingress" {
#   name       = "nginx-ingress"
#   repository = "bitnami"                          # Use Bitnami repository name directly
#   chart      = "nginx-ingress-controller"
#   version    = "11.4.4"                           # Ensure this version exists in the repository
#   namespace  = kubernetes_namespace.nginxns.metadata[0].name  # Use the created namespace

#   values = [
#     <<EOF
#     controller:
#       service:
#         enabled: true
#         type: LoadBalancer
#         annotations:
#           cloud.google.com/load-balancer-type: "External"
#           # Add any additional annotations here
#         loadBalancerIP: "34.49.216.82"  # Specify your static external IP here
#     EOF
#   ]
# }

# Deploy the NGINX Ingress Controller using Helm from the official nginx-stable repository
resource "helm_release" "nginx_ingress" {
  depends_on = [ google_container_node_pool.primary_nodes ]
  name       = "nginx-ingress"
  repository = "nginx-stable"                     # Use the official NGINX repository
  chart      = "nginx-ingress"                    # Use the chart name for NGINX Ingress Controller
  version    = "1.4.0"                            # Specify the desired chart version (check the available versions - "helm search repo nginx-stable/nginx-ingress --versions")
  namespace  = kubernetes_namespace.nginxns.metadata[0].name  # Use the created namespace

  values = [
    <<EOF
controller:
  service:
    enabled: true
    annotations:
      cloud.google.com/load-balancer-type: "External"  # Specify load balancer type
    loadBalancerIP: "34.49.216.82"  # Specify your static external IP here
EOF
  ]
}

# Output the NGINX Ingress Controller service endpoint
output "nginx_ingress_service" {
  value = helm_release.nginx_ingress.status
}
