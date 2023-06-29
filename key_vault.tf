locals {
  key_vault_name = upper("FOO-${var.application_info.app_name}-${var.application_info.environment}-KEY-${var.application_info.function}")
}

data "azurerm_client_config" "current" {}

data "azuread_group" "kv_aad_group" {
  display_name     = var.aad_group_names.keyvault 
  security_enabled = true
}

resource "azurerm_key_vault" "kv" {
  location                  = azurerm_resource_group.rg.location
  name                      = local.key_vault_name
  resource_group_name       = azurerm_resource_group.rg.name
  sku_name                  = "standard"
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  enable_rbac_authorization = true

  lifecycle {
    precondition {
      condition     = length(local.key_vault_name) > 2 && length(local.key_vault_name) < 25 && can(regex("^[a-zA-Z0-9\\-]+$", local.key_vault_name))
      error_message = "Key Vault name length must be between 3 and 24 characters with only lowercase alphanumerics and hyphens"
    }
  }
}

resource "azurerm_role_assignment" "kv_sp_admin" {
  scope                 = azurerm_resource_group.rg.id
  role_definition_name  = "Key Vault Administrator"
  principal_id          = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_secret" "vm_admin_name" {
  for_each = var.virtual_machine_list

  name         = "${each.key}-username"
  value        = "${each.value.vm_admin_name_prefix}-${var.application_info.app_name}"
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [ azurerm_role_assignment.kv_sp_admin ]
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

  depends_on = [ azurerm_role_assignment.kv_sp_admin ]
}

resource "azurerm_role_assignment" "kv_aad_group" {
  scope                 = azurerm_resource_group.rg.id
  role_definition_name  = "Key Vault Administrator"
  principal_id          = data.azuread_group.kv_aad_group.object_id
}
