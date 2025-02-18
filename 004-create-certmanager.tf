

#By using this Terraform configuration, you should be able to resolve the RBAC issue and allow the cert-manager-cainjector service account to create Lease resources for leader election

provider "kubernetes" {
  config_path = "~/.kube/config"  # Adjust this path if your kubeconfig is located elsewhere
}

resource "kubernetes_role" "cert_manager_cainjector_leader_election" {
  metadata {
    name      = "cert-manager-cainjector-leader-election"
    namespace = "cert-manager"
  }

  rule {
    api_groups = ["coordination.k8s.io"]
    resources  = ["leases"]
    verbs      = ["get", "watch", "list", "create", "update", "patch"]
  }
}

resource "kubernetes_role_binding" "cert_manager_cainjector_leader_election" {
  metadata {
    name      = "cert-manager-cainjector-leader-election"
    namespace = "cert-manager"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.cert_manager_cainjector_leader_election.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "cert-manager-cainjector"
    namespace = "cert-manager"
  }
}

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

  depends_on = [
    kubernetes_role.cert_manager_cainjector_leader_election,
    kubernetes_role_binding.cert_manager_cainjector_leader_election
  ]
}
