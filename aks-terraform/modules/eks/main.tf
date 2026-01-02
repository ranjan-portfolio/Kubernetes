resource "azurerm_kubernetes_cluster" "default" {
  name                = "${var.random_id}-aks"
  location            = var.location
  resource_group_name = var.name
  dns_prefix          = "${var.random_id}-k8s"
  kubernetes_version  = "1.34"
  oidc_issuer_enabled = true 

  default_node_pool {
    name            = "default"
    node_count      = 1
    vm_size         = "Standard_D2_v4"
    os_disk_size_gb = 30
  }

 identity {
  type = "SystemAssigned"
 }

  role_based_access_control_enabled = true

  tags = {
    environment = "Demo"
  }
}


