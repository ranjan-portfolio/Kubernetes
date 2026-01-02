output "aks_cluster_name" {
  value       = module.eks.kubernetes_cluster_name
  description = "AKS cluster name from module.eks"
}

output "aks_resource_group_name" {
  value       = module.resource_group.resource_group_name
  description = "This is resource group name"
}


