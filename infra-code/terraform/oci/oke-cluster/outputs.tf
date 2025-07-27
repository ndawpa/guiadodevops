output "cluster_name" {
  value = module.oke_cluster.cluster_id
}

output "endpoint" {
  value = module.oke_cluster.cluster_endpoints
}

output "oke_vcn_id" {
  value = module.oke_cluster.vcn_id
}

output "cluster_kubeconfig" {
  value = module.oke_cluster.cluster_kubeconfig
}