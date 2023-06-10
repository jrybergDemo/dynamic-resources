# TODO: Move to remote backend

terraform {
  backend "azurerm" {
      environment = "usgovernment"
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.55.0"
    }
  }
}

provider "azurerm" {
  features {}
  environment = "usgovernment"
}
