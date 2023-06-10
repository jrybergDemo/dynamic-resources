locals {
  deploy_rsv = var.backup_services != "" ? 1 : 0

  rsv_name = upper("FOO-${var.application_info.app_name}-${var.application_info.environment}-RSV-${var.application_info.function}")
}

resource "azurerm_recovery_services_vault" "rsv" {
  count                        = local.deploy_rsv
  cross_region_restore_enabled = true
  location                     = azurerm_resource_group.rg.location
  name                         = local.rsv_name
  resource_group_name          = azurerm_resource_group.rg.name
  sku                          = "RS0"
  
  lifecycle {
    precondition {
      condition     = length(local.rsv_name) > 2 && length(local.rsv_name) < 51 && can(regex("^[a-zA-Z0-9\\-]+$", local.key_vault_name))
      error_message = "Key Vault name length must be between 3 and 24 characters with only lowercase alphanumerics and hyphens"
    }
  }
}

resource "azurerm_backup_policy_vm" "daily" {
  count               = local.deploy_rsv
  name                = "DefaultPolicy"
  recovery_vault_name = azurerm_recovery_services_vault.rsv[count.index].name
  resource_group_name = azurerm_resource_group.rg.name

  backup {
    frequency = "Daily"
    time      = "06:00"
  }

  retention_daily {
    count = 30
  }
}

resource "azurerm_backup_policy_vm" "hourly" {
  count               = local.deploy_rsv
  name                = "EnhancedPolicy"
  policy_type         = "V2"
  recovery_vault_name = azurerm_recovery_services_vault.rsv[count.index].name
  resource_group_name = azurerm_resource_group.rg.name

  backup {
    frequency     = "Hourly"
    hour_duration = 12
    hour_interval = 4
    time          = "08:00"
  }

  retention_daily {
    count = 30
  }
}

resource "azurerm_backup_policy_vm_workload" "sql" {
  count               = local.deploy_sql_db
  name                = "HourlyLogBackup"
  recovery_vault_name = azurerm_recovery_services_vault.rsv[count.index].name
  resource_group_name = azurerm_resource_group.rg.name
  workload_type       = "SQLDataBase"

  protection_policy {
    policy_type = "Log"

    backup {
      frequency_in_minutes = 60
    }

    simple_retention {
      count = 30
    }
  }

  protection_policy {
    policy_type = "Full"

    backup {
      frequency = "Daily"
      time      = "06:00"
    }

    retention_daily {
      count = 30
    }
  }

  settings {
    time_zone = "UTC"
  }
}