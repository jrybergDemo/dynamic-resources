locals {
  deploy_sql_db = var.sql_database.server_name == null ? 0 : 1
}

data "azurerm_mssql_server" "shared" {
  count               = local.deploy_sql_db
  name                = var.sql_database.server_name
  resource_group_name = var.sql_database.database_rg_name
}

resource "azurerm_mssql_database" "db" {
  count                = local.deploy_sql_db
  name                 = upper("FOO-${var.application_info.app_name}-${var.application_info.environment}-SMI-${var.application_info.function}")
  server_id            = data.azurerm_mssql_server.shared[count.index].id
  collation            = "SQL_Latin1_General_CP1_CI_AS"
  ledger_enabled       = false
  license_type         = "LicenseIncluded"
  max_size_gb          = 256
  read_scale           = false
  sku_name             = "ElasticPool"
  storage_account_type = "Geo"
  zone_redundant       = false
}
