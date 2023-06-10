locals {
  deploy_web_app = var.web_app.service_plan_name == null ? 0 : 1

  web_app_name = upper("FOO-${var.application_info.app_name}-${var.application_info.environment}-APP-${var.application_info.function}")
}

data "azurerm_app_service_environment" "ase" {
  count               = local.deploy_web_app
  name                = var.web_app.service_environment_name
  resource_group_name = var.web_app.service_environment_resource_group
}

resource "azurerm_service_plan" "asp" {
  count                      = local.deploy_web_app
  app_service_environment_id = data.azurerm_app_service_environment.ase[count.index].id
  location                   = azurerm_resource_group.rg.location
  name                       = var.web_app.service_plan_name
  os_type                    = "Windows"
  resource_group_name        = azurerm_resource_group.rg.name
  sku_name                   = "I1"
}

resource "azurerm_windows_web_app" "app" {
  count                      = local.deploy_web_app
  client_affinity_enabled    = true
  client_certificate_enabled = true
  client_certificate_mode    = "Optional"
  https_only                 = true
  location                   = azurerm_resource_group.rg.location
  name                       = local.web_app_name
  resource_group_name        = azurerm_resource_group.rg.name
  service_plan_id            = azurerm_service_plan.asp[count.index].id

  backup {
    name                = local.web_app_name
    storage_account_url = data.azurerm_storage_account_sas.app.sas

    schedule {
      frequency_interval       = 1
      frequency_unit           = "Day"
      keep_at_least_one_backup = true
      retention_period_days    = 10
    }
  }

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on     = false
    ftps_state    = "FtpsOnly"
    http2_enabled = true

    virtual_application {
      physical_path = "site\\wwwroot"
      preload       = false
      virtual_path  = "/"
    }
  }
}

resource "azurerm_app_service_custom_hostname_binding" "app" {
  count               = local.deploy_web_app
  app_service_name    = azurerm_windows_web_app.app[count.index].name
  hostname            = azurerm_windows_web_app.app[count.index].default_hostname
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_windows_web_app_slot" "app" {
  count                   = local.deploy_web_app
  app_service_id          = azurerm_windows_web_app.app[count.index].id
  client_affinity_enabled = true
  name                    = var.web_app.app_service_slot_name

  site_config {
    always_on  = false
    ftps_state = "AllAllowed"

    virtual_application {
      physical_path = "site\\wwwroot"
      preload       = false
      virtual_path  = "/"
    }
  }
}

resource "azurerm_app_service_slot_custom_hostname_binding" "app" {
  count               = local.deploy_web_app
  app_service_slot_id = azurerm_windows_web_app_slot.app[count.index].id
  hostname            = azurerm_windows_web_app_slot.app[count.index].default_hostname
}

data "azurerm_monitor_action_group" "web_app" {
  count               = local.deploy_web_app
  resource_group_name = var.web_app.alert_action_group_rg_name
  name                = var.web_app.alert_action_group_name
}

# TODO: Make this resource actually work
resource "azurerm_monitor_smart_detector_alert_rule" "web_app" {
  count               = local.deploy_web_app
  description         = "Failure Anomalies notifies you of an unusual rise in the rate of failed HTTP requests or dependency calls."
  detector_type       = "FailureAnomaliesDetector"
  frequency           = "PT1M"
  name                = "Failure Anomalies - ${local.web_app_name}"
  resource_group_name = azurerm_resource_group.rg.name
  scope_resource_ids  = [azurerm_windows_web_app.app[count.index].id]
  severity            = "Sev3"
  action_group {
    ids = [data.azurerm_monitor_action_group.web_app[count.index].id]
  }
}

# TODO: Rename this resource from res-61 to web_app_insights & do a tf state mv
resource "azurerm_application_insights" "web_app_insights" {
  count               = local.deploy_web_app
  application_type    = "web"
  location            = azurerm_resource_group.rg.location
  name                = local.web_app_name
  resource_group_name = azurerm_resource_group.rg.name
  sampling_percentage = 0
}
