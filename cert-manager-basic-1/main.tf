
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.cert_manager_version
  namespace  = "cert-manager"

  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }

  wait          = true
  wait_for_jobs = true
  timeout       = 600
}

resource "time_sleep" "wait_for_cert_manager" {
  depends_on = [helm_release.cert_manager]
  create_duration = "30s"
}

resource "kubectl_manifest" "selfsigned_cluster_issuer" {
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-cluster-issuer
spec:
  selfSigned: {}
YAML

  depends_on = [time_sleep.wait_for_cert_manager]
}

resource "kubectl_manifest" "ca_certificate" {
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: selfsigned-ca
  namespace: cert-manager
spec:
  isCA: true
  commonName: "Local Development CA"
  secretName: selfsigned-ca-secret
  privateKey:
    algorithm: RSA
    size: 2048
  duration: 8760h
  renewBefore: 720h
  issuerRef:
    name: selfsigned-cluster-issuer
    kind: ClusterIssuer
    group: cert-manager.io
YAML

  depends_on = [kubectl_manifest.selfsigned_cluster_issuer]
}

resource "kubectl_manifest" "ca_cluster_issuer" {
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: ca-cluster-issuer
spec:
  ca:
    secretName: selfsigned-ca-secret
YAML

  depends_on = [kubectl_manifest.ca_certificate]
}
