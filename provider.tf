terraform {
  backend "azurerm" {
    environment = "usgovernment"
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.55.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.39.0"
    }
  }
}

provider "azurerm" {
  features {}
  environment = "usgovernment"
}

provider "azuread" {
  environment = "usgovernment"
}

