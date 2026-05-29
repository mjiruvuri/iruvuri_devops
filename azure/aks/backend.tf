terraform {
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "iruvuritfstate"
    container_name       = "tfstate"
    key                  = "aks/terraform.tfstate"
  }
}
