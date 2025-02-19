#helm install   cert-manager jetstack/cert-manager   --namespace cert-manager   --create-namespace   --version v1.11.1   --set installCRDs=true   --set global.leaderElection.namespace=cert-manager
resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  version          = "v1.17.0"
  namespace        = "cert-manager"
  create_namespace = true

  set {
    name  = "crds.enabled"
    value = "true"
  }

  set {
    name  = "global.leaderElection.namespace"
    value = "cert-manager"
  }
}

resource "kubernetes_manifest" "letsencrypt_prod_cluster_issuer" {
  depends_on = [helm_release.cert_manager]

  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "ClusterIssuer"
    "metadata" = {
      "name" = "letsencrypt-prod"
    }
    "spec" = {
      "acme" = {
        "server" = "https://acme-v02.api.letsencrypt.org/directory"
        "email"  = "raj.manda@gmail.com"
        "privateKeySecretRef" = {
          "name" = "letsencrypt-prod"
        }
        "solvers" = [
          {
            "http01" = {
              "ingress" = {
                "class" = "nginx" # or the ingress controller you are using
              }
            }
          }
        ]
      }
    }
  }
}

resource "kubernetes_manifest" "rajmanda-dev-letsencrypt-prod-tls_kalyanamns_certificate" {
  depends_on = [kubernetes_manifest.letsencrypt_prod_cluster_issuer]

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "rajmanda-dev-letsencrypt-prod-tls"
      namespace = "kalyanam" ###namespace as the service that the nginx controller is mapping to
    }
    spec = {
      secretName = "rajmanda-dev-letsencrypt-prod-tls"
      dnsNames   = ["rajmanda-dev.com", "shravanikalyanam.com"]
      issuerRef = {
        name = "letsencrypt-prod"
        kind = "ClusterIssuer"
      }
    }
  }
}

resource "kubernetes_manifest" "rajmanda-dev-letsencrypt-prod-tls_eurekans_certificate" {
  depends_on = [kubernetes_manifest.letsencrypt_prod_cluster_issuer]

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "Certificate"
    metadata = {
      name      = "rajmanda-dev-letsencrypt-prod-tls"
      namespace = "eureka" ###namespace as the service that the nginx controller is mapping to
    }
    spec = {
      secretName = "rajmanda-dev-letsencrypt-prod-tls"
      dnsNames   = ["rajmanda-dev.com", "shravanikalyanam.com"]
      issuerRef = {
        name = "letsencrypt-prod"
        kind = "ClusterIssuer"
      }
    }
  }
}
