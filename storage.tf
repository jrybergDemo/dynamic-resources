locals {
  storage_account_name = lower("foo${var.application_info.app_name}${var.application_info.environment}stg${var.application_info.function}")
}

resource "azurerm_storage_account" "sa" {
  account_kind                    = var.storage_account.kind
  account_replication_type        = var.storage_account.replication_type
  account_tier                    = var.storage_account.tier
  allow_nested_items_to_be_public = false
  location                        = azurerm_resource_group.rg.location
  min_tls_version                 = "TLS1_2"
  name                            = local.storage_account_name
  resource_group_name             = azurerm_resource_group.rg.name

  lifecycle {
    precondition {
      condition     = length(local.storage_account_name) > 2 && length(local.storage_account_name) < 25 && can(regex("^[a-z0-9]+$", local.storage_account_name))
      error_message = "Storage Account name length must be between 3 and 24 characters with only lowercase letters and numbers"
    }
  }
}

resource "azurerm_storage_container" "container" {
  name                 = var.storage_account.container_name
  storage_account_name = azurerm_storage_account.sa.name
}

data "azurerm_storage_account_sas" "app" {
  connection_string = azurerm_storage_account.sa.primary_connection_string
  https_only        = true
  signed_version    = "2017-07-29"

  resource_types {
    service   = false
    container = true
    object    = false
  }

  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }

  start  = timestamp()
  expiry = timeadd(timestamp(), "43800h")

  permissions {
    read    = true
    write   = true
    delete  = true
    list    = true
    add     = false
    create  = false
    update  = false
    process = false
    tag     = false
    filter  = false
  }
}

data "azurerm_subnet" "sa_subnet" {
  name                 = var.storage_account.private_endpoint.subnet_name
  virtual_network_name = var.storage_account.private_endpoint.virtual_network_name
  resource_group_name  = var.storage_account.private_endpoint.virtual_network_resource_group
}

resource "azurerm_network_interface" "sa-pep" {
  location            = azurerm_resource_group.rg.location
  name                = "${azurerm_storage_account.sa.name}_nic"
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "${azurerm_storage_account.sa.name}_pep_nic_config"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = data.azurerm_subnet.sa_subnet.id
  }
}

data "azurerm_private_dns_zone" "sa-pep" {
  name                = "privatelink.blob.core.usgovcloudapi.net"
  resource_group_name = var.storage_account.private_endpoint.virtual_network_resource_group
}

resource "azurerm_private_endpoint" "sa-pep" {
  location            = azurerm_resource_group.rg.location
  name                = "${azurerm_storage_account.sa.name}_pep"
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = data.azurerm_subnet.sa_subnet.id

  private_dns_zone_group {
    name                 = "${azurerm_storage_account.sa.name}_pep_group"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.sa-pep.id]
  }

  private_service_connection {
    is_manual_connection           = false
    name                           = "${azurerm_storage_account.sa.name}_blob_pep"
    private_connection_resource_id = azurerm_storage_account.sa.id
    subresource_names              = ["blob"]
  }
}
