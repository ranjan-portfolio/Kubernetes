output "location"{
    value=azurerm_resource_group.default.location
    description="This is the resource group location"
}

output "resource_group_name"{
    value=azurerm_resource_group.default.name
    description="This is resource group name"
}

