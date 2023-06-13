terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "random_pet" "name" {
  separator = ""
}
resource "random_integer" "int" {
  min = 10000
  max = 99999
}

locals {
  app_name = "${random_pet.name.id}${random_integer.int.result}"
  location = "westus3"
}

resource "azurerm_resource_group" "rg" {
  name     = "${local.app_name}-rg"
  location = local.location
}

resource "azurerm_service_plan" "asp" {
  name                = "${local.app_name}-asp"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Windows"
  sku_name            = "Y1"
}

resource "azurerm_storage_account" "sa" {
  name                     = "${local.app_name}sa"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_windows_function_app" "funcapp" {
  name                = "${local.app_name}-funcapp"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  service_plan_id     = azurerm_service_plan.asp.id

  storage_account_name       = azurerm_storage_account.sa.name
  storage_account_access_key = azurerm_storage_account.sa.primary_access_key

  site_config {
    application_stack {
      powershell_core_version = "7"
    }
  }

  lifecycle {
    ignore_changes = [
      app_settings["WEBSITE_ENABLE_SYNC_UPDATE_SITE"],
      app_settings["WEBSITE_RUN_FROM_PACKAGE"]
    ]
  }
}
