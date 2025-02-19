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

resource "kubernetes_manifest" "letsencrypt_staging_issuer" {
  depends_on = [helm_release.cert_manager]

  manifest = {
    "apiVersion" = "cert-manager.io/v1"
    "kind"       = "Issuer"
    "metadata" = {
      "name"      = "letsencrypt-staging"
      "namespace" = "cert-manager" # make sure the namespace matches where cert-manager is installed
    }
    "spec" = {
      "acme" = {
        "server" = "https://acme-staging-v02.api.letsencrypt.org/directory"
        "email"  = "raj.manda@gmail.com" 
        "privateKeySecretRef" = {
          "name" = "letsencrypt-staging"
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
