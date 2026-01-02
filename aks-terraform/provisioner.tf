terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.53.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.7.2"
    }
  }

  backend "azurerm" {
    resource_group_name  = "TerraformStateRG" 
    storage_account_name = "uniquestatesaname12345" 
    container_name       = "tfstate"          
    key                  = "aks-cluster.tfstate" # Name of the state file blob
  }

  required_version = ">= 1.1"

}
