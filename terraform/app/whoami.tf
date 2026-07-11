resource "kubernetes_deployment" "whoami" {
  metadata {
    name = "whoami"
    labels = {
      app = "whoami"
    }
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "whoami"
      }
    }

    template {
      metadata {
        labels = {
          app = "whoami"
        }
      }

      spec {
        container {
          name  = "whoami"
          image = "traefik/whoami:v1.10"

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

# ClusterIP: reachable inside the cluster and via `kubectl port-forward` for
# verification. Not a LoadBalancer — a public-facing load balancer is a
# bigger, costlier commitment than a "reachable" sample app calls for, and
# this cluster's guardrail policy (scripts/hooks/terraform-checker.sh)
# blocks LoadBalancer-type services outright.
resource "kubernetes_service" "whoami" {
  metadata {
    name = "whoami"
    labels = {
      app = "whoami"
    }
  }

  spec {
    selector = {
      app = "whoami"
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "ClusterIP"
  }
}
