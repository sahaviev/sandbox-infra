# ArgoCD TLS Certificate using cert-manager
resource "kubectl_manifest" "argocd_certificate" {
  yaml_body = <<YAML
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: argocd-server-tls
  namespace: ${var.namespace}
spec:
  secretName: argocd-server-tls
  duration: 2160h # 90 days
  renewBefore: 360h # 15 days
  commonName: ${var.ingress_hostname}
  dnsNames:
  - ${var.ingress_hostname}
  - localhost
  ipAddresses:
  - 127.0.0.1
  issuerRef:
    name: ca-cluster-issuer
    kind: ClusterIssuer
    group: cert-manager.io
YAML
}
