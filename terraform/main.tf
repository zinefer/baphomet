provider "azurerm" {
  version = "~> 2.4.0" # https://github.com/terraform-providers/terraform-provider-azurerm/issues/1109
  features {}
}

variable "token" {
  type = string
}

data "azurerm_client_config" "current" {}

locals {
  app_name = "baphomet-bot"
}

# Render a part using a `template_file`
data "template_file" "cloud_init" {
  template = file("cloud-init.tpl")

  vars = {
    token = var.token
  }
}

data "template_cloudinit_config" "baphomet" {
  base64_encode = true

  # Main cloud-config configuration file.
  part {
    filename     = "cloud-init.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.cloud_init.rendered
  }
}

resource "azurerm_resource_group" "baphomet" {
  name     = local.app_name
  location = "South Central US"
}

resource "azurerm_key_vault" "baphomet" {
  name                = "${local.app_name}-kv"
  location            = azurerm_resource_group.baphomet.location
  resource_group_name = azurerm_resource_group.baphomet.name
  
  sku_name  = "standard"
  tenant_id = data.azurerm_client_config.current.tenant_id

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions     = [ "list", "get", "create", "update", "delete" ]
    secret_permissions  = [ "list", "get", "set", "delete" ]
  }
}

resource "azurerm_key_vault_secret" "baphomet" {
  name         = "discord-token"
  value        = var.token
  key_vault_id = azurerm_key_vault.baphomet.id
}

resource "azurerm_virtual_network" "baphomet" {
  name                = "${local.app_name}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.baphomet.location
  resource_group_name = azurerm_resource_group.baphomet.name
}

resource "azurerm_subnet" "baphomet" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.baphomet.name
  virtual_network_name = azurerm_virtual_network.baphomet.name
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_public_ip" "baphomet" {
  name                    = "baphomet-debug"
  location                = azurerm_resource_group.baphomet.location
  resource_group_name     = azurerm_resource_group.baphomet.name
  allocation_method       = "Dynamic"
  idle_timeout_in_minutes = 30
}

resource "azurerm_network_interface" "baphomet" {
  name                = "${local.app_name}-nic"
  location            = azurerm_resource_group.baphomet.location
  resource_group_name = azurerm_resource_group.baphomet.name

  ip_configuration {
    name                          = "ipconf"
    subnet_id                     = azurerm_subnet.baphomet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.baphomet.id
  }
}

resource "azurerm_linux_virtual_machine" "baphomet" {
  name                = "${local.app_name}-vm"
  resource_group_name = azurerm_resource_group.baphomet.name
  location            = azurerm_resource_group.baphomet.location
  size                = "Standard_B1S"
  
  custom_data = data.template_cloudinit_config.baphomet.rendered
  
  admin_username      = "adminuser"
  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  network_interface_ids = [
    azurerm_network_interface.baphomet.id,
  ]

  identity {
    type = "SystemAssigned"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_key_vault_access_policy" "baphomet" {
  key_vault_id = azurerm_key_vault.baphomet.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = azurerm_linux_virtual_machine.baphomet.identity.0.principal_id

  key_permissions    = [ "get" ]
  secret_permissions = [ "get" ]
}