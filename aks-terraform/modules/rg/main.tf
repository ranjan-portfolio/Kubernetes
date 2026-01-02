resource "azurerm_resource_group" "default" {
  name     = "${var.name}-rg"
  location = "West US 2" 
}


