
output "cluster_issuers" {
  description = "Available ClusterIssuers"
  value = {
    "selfsigned-cluster-issuer" = "Basic self-signed certificates"
    "ca-cluster-issuer"         = "CA-signed certificates (recommended)"
  }
}

output "ca_certificate_command" {
  description = "Get CA certificate for browser trust"
  value = "kubectl get secret selfsigned-ca-secret -n cert-manager -o jsonpath='{.data.tls\\.crt}' | base64 -d > local-ca.crt"
}
