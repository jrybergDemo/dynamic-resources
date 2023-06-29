locals {
  deploy_sql_db = var.sql_database.server_name == null ? 0 : 1
}

data "azurerm_mssql_server" "shared" {
  count               = local.deploy_sql_db
  name                = var.sql_database.server_name
  resource_group_name = var.sql_database.database_rg_name
}

data "azurerm_mssql_elasticpool" "pool" {
  count               = local.deploy_sql_db
  name                = var.sql_database.elastic_pool_name
  resource_group_name = var.sql_database.database_rg_name
  server_name         = var.sql_database.server_name
}

resource "azurerm_mssql_database" "db" {
  count                = local.deploy_sql_db
  name                 = upper("FOO-${var.application_info.app_name}-${var.application_info.environment}-SMI-${var.application_info.function}")
  server_id            = data.azurerm_mssql_server.shared[count.index].id
  collation            = "SQL_Latin1_General_CP1_CI_AS"
  ledger_enabled       = false
  elastic_pool_id      = data.azurerm_mssql_elasticpool.pool[count.index].id
  license_type         = "LicenseIncluded"
  max_size_gb          = 256
  read_scale           = false
  sku_name             = "ElasticPool"
  storage_account_type = "Geo"
  zone_redundant       = false
}

resource "random_password" "sql_admin_password" {
  for_each = {
    for vmname, vm in var.virtual_machine_list : vmname => vm
    if vm.source_image_publisher == "MicrosoftSQLServer"
  }

  length           = 24
  numeric          = true
  lower            = true
  upper            = true
  override_special = "_%@!#="
  special          = true
}

resource "azurerm_key_vault_secret" "sql_admin_password" {
  for_each = {
    for vmname, vm in var.virtual_machine_list : vmname => vm
    if vm.source_image_publisher == "MicrosoftSQLServer"
  }

  name         = "${each.key}-sql-password"
  value        = random_password.sql_admin_password[each.key].result
  key_vault_id = azurerm_key_vault.kv.id
}

resource "azurerm_mssql_virtual_machine" "list" {
  for_each = {
    for vmname, vm in var.virtual_machine_list : vmname => vm
    if vm.source_image_publisher == "MicrosoftSQLServer"
  }

  r_services_enabled               = each.value.mssql_vm_configuration.r_services_enabled
  sql_connectivity_port            = each.value.mssql_vm_configuration.sql_connectivity_port
  sql_connectivity_type            = each.value.mssql_vm_configuration.sql_connectivity_type
  sql_license_type                 = each.value.mssql_vm_configuration.sql_license_type
  virtual_machine_id               = azurerm_windows_virtual_machine.list[each.key].id

  auto_patching {
    day_of_week                            = each.value.mssql_vm_configuration.sql_patching_day_of_week
    maintenance_window_duration_in_minutes = each.value.mssql_vm_configuration.sql_patching_maintenance_window_duration_in_minutes
    maintenance_window_starting_hour       = each.value.mssql_vm_configuration.sql_patching_maintenance_window_starting_hour
  }

  storage_configuration {
    disk_type             = "NEW"
    storage_workload_type = "GENERAL"
    data_settings {
      default_file_path = "F:\\data"
      luns              = [0]
    }
    log_settings {
      default_file_path = "L:\\log"
      luns              = [1]
    }
     temp_db_settings {
      default_file_path = "D:\\tempdb"
      luns              = []
    }
  }

  depends_on = [ azurerm_virtual_machine_data_disk_attachment.list ]
}
