locals {
  values = {
    configs = {
      params = {
        "server.insecure" = false
      }

      # Generate user passwords
      secret = {
        extra = length(var.argocd_users) > 0 ? merge(
          {
            for username, user in var.argocd_users :
            "accounts.${username}.password" => bcrypt(random_password.user_passwords[username].result)
          },
          {
            for username, user in var.argocd_users :
            "accounts.${username}.passwordMtime" => timestamp()
          }
        ) : {}
      }

      # Generate role policies with user bindings
      rbac = length(var.argocd_roles) > 0 ? {
        "policy.csv" = join("\n", flatten([
          for rolename, role in var.argocd_roles : concat(
            role.policies,
            [for username, user in var.argocd_users : "g, ${username}, role:${rolename}" if user.role == rolename]
          )
        ]))
        "scopes" = "[groups]"
      } : {}

      # Generate user configuration
      cm = length(var.argocd_users) > 0 ? merge(
        {
          for username, user in var.argocd_users :
          "accounts.${username}" => join(",", user.capabilities)
        },
        {
          for username, user in var.argocd_users :
          "accounts.${username}.enabled" => tostring(user.enabled)
        }
      ) : {}
    }

    server = {
      ingress = {
        enabled          = var.ingress_enabled
        ingressClassName = "nginx"
        annotations = {
          "kubernetes.io/ingress.class"                  = "nginx"
          "cert-manager.io/cluster-issuer"               = "ca-cluster-issuer"
          "nginx.ingress.kubernetes.io/backend-protocol" = "HTTPS"
          "nginx.ingress.kubernetes.io/ssl-redirect"     = "true"
        }
        hosts = [var.ingress_hostname]
        tls = [
          {
            hosts = [var.ingress_hostname]
            secretName = "argocd-server-tls"
          }
        ]
      }
      service = {
        type = "ClusterIP"
        ports = {
          https = 443
        }
      }
    }
    controller = {
      replicas = 1
    }
    repoServer = {
      replicas = 1
    }
    applicationSet = {
      replicas = 1
    }
    dex = {
      enabled = false
    }
    redis = {
      enabled = true
    }
  }
}
