
# cert-manager service account does not have the necessary permissions to create a leader election record in the kube-system namespace - hence creating this namespace.
# resource "kubernetes_namespace" "cert-manager-leader-election" {
#   #depends_on = [module.kubernetes-engine_example_simple_autopilot_public]
#   #depends_on = [ data.google_container_cluster.existing ]
#   metadata {
#     name = "cert-manager-leader-election"
#   }
# }


resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.17.0"
  namespace  = "cert-manager"
  create_namespace = true

  set {
    name  = "crds.enabled"
    value = "true"
  }

  set {
    name  = "prometheus.enabled"
    value = "false"
  }

  set {
    name  = "webhook.timeoutSeconds"
    value = "4"
  }
}
