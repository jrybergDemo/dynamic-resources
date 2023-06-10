locals {
  key_vault_name = upper("FOO-${var.application_info.app_name}-${var.application_info.environment}-KEY-${var.application_info.function}")
}

data "azurerm_client_config" "current" { }

resource "azurerm_key_vault" "kv" {
  location            = azurerm_resource_group.rg.location
  name                = local.key_vault_name
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "standard"
  tenant_id           = data.azurerm_client_config.current.tenant_id

  lifecycle {
    precondition {
      condition     = length(local.key_vault_name) > 2 && length(local.key_vault_name) < 25 && can(regex("^[a-zA-Z0-9\\-]+$", local.key_vault_name))
      error_message = "Key Vault name length must be between 3 and 24 characters with only lowercase alphanumerics and hyphens"
    }
  }
}

resource "azurerm_key_vault_secret" "vm_admin_name" {
  for_each = var.virtual_machine_list

  name         = "${each.key}-username"
  value        = "${each.value.vm_admin_name_prefix}-${var.application_info.app_name}"
  key_vault_id = azurerm_key_vault.kv.id
}

resource "random_password" "vm_admin_pasword" {
  for_each = var.virtual_machine_list

  length           = 24
  numeric          = true
  lower            = true
  upper            = true
  override_special = "_%@!#="
  special          = true
}

resource "azurerm_key_vault_secret" "vm_admin_password" {
  for_each = var.virtual_machine_list

  name         = "${each.key}-password"
  value        = random_password.vm_admin_pasword[each.key].result
  key_vault_id = azurerm_key_vault.kv.id
}

# TODO: add RBAC for KV Owner - do we create the Group?
# resource "azurerm_role_assignment" "example" {
#   name               = "00000000-0000-0000-0000-000000000000"
#   scope              = data.azurerm_subscription.primary.id
#   role_definition_id = azurerm_role_definition.example.role_definition_resource_id
#   principal_id       = data.azurerm_client_config.example.object_id
# }
