terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Remote state: uncomment and fill in once you have a storage account + container.
  # backend "azurerm" {
  #   resource_group_name  = "<tfstate-rg>"
  #   storage_account_name = "<tfstate-storage-account>"
  #   container_name       = "tfstate"
  #   key                  = "devops-demo/azure-aks.tfstate"
  # }
}

provider "azurerm" {
  features {}
}
