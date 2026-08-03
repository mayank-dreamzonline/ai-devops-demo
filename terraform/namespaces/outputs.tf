output "namespace_names" {
  value = [
    kubernetes_namespace.dev.metadata[0].name,
    kubernetes_namespace.staging.metadata[0].name,
    kubernetes_namespace.prod.metadata[0].name,
  ]
}
