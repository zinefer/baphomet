provider "azurerm" {
  version = "~> 2.4.0" # https://github.com/terraform-providers/terraform-provider-azurerm/issues/1109
  features {}
}

variable "token" {
  type = string
}

data "http" "icanhazip" {
   url = "http://icanhazip.com"
}

resource "random_pet" "baphomet" {
  length = 1
}

locals {
  app_name = "baphomet-bot"
  qualified_app_name = "${local.app_name}-${random_pet.baphomet.id}"
  qualified_app_name_clean = replace(local.qualified_app_name, "-", "")
  my_ip = chomp(data.http.icanhazip.body)
}

resource "azurerm_resource_group" "baphomet" {
  name     = local.app_name
  location = "South Central US"
}

resource "azurerm_storage_account" "baphomet" {
  name                     = local.qualified_app_name_clean
  resource_group_name      = azurerm_resource_group.baphomet.name
  location                 = azurerm_resource_group.baphomet.location
  account_tier             = "Standard"
  //account_tier             = "StorageV2"
  account_replication_type = "LRS"

  /*network_rules {
      default_action = "Deny"
      bypass   = ["AzureServices"]
      ip_rules = [local.my_ip]
  }*/
}

resource "azurerm_storage_share" "baphomet" {
  name                 = "data"
  storage_account_name = azurerm_storage_account.baphomet.name
}

resource "azurerm_app_service_plan" "baphomet" {
  name                = "${local.app_name}-service"
  location            = azurerm_resource_group.baphomet.location
  resource_group_name = azurerm_resource_group.baphomet.name

  reserved = true
  kind = "Linux"

  sku {
    tier = "Basic"
    size = "B1"
  }
}

resource "azurerm_app_service" "baphomet" {
  name                = local.qualified_app_name
  location            = azurerm_resource_group.baphomet.location
  resource_group_name = azurerm_resource_group.baphomet.name
  app_service_plan_id = azurerm_app_service_plan.baphomet.id

  identity {
    type = "SystemAssigned"
  }

  logs {
    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 100
      }
    }
  }

  storage_account {
      name = "data"
      type = "AzureFiles"
      account_name = azurerm_storage_account.baphomet.name
      share_name = azurerm_storage_share.baphomet.name
      access_key = azurerm_storage_account.baphomet.primary_access_key
      mount_path = "/data"
  }

  site_config {
    always_on        = true
    linux_fx_version = "DOCKER|zinefer/baphomet:latest"
  }

  app_settings = {
    TOKEN = var.token
    PREFIX = "!"
    PUID = 0
    GUID = 0
    DOCKER_ENABLE_CI = true
    CONTAINER_AVAILABILITY_CHECK_MODE = "ReportOnly"
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = false
  }
}

resource "azurerm_role_assignment" "baphomet" {
  scope                = azurerm_storage_account.baphomet.id
  role_definition_name = "Storage File Data SMB Share Contributor"
  principal_id         = azurerm_app_service.baphomet.identity[0].principal_id
}