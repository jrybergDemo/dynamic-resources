application_info = {
  app_name    = "foo"
  environment = "D"
  function    = "APP"
  project     = "FOO"
  unit_long   = "BAR"
  unit_short  = "BARBAZ"
}

### AAD groups to assign RBAC per resource
aad_group_names = { 
  keyvault = "SG-KV-HQG8-TIGER-T01"
}

backup_services = true

domain_join = {
  domain_fqdn = "foo.army.mil"
  ou_path     = ""
  username    = "foo\\service_account" # escape the backslash
}

resource_group = {
  location = "usgovvirginia"
  tags = {
    key = "value"
  }
}

storage_account = {
  container_name = "backup"
  kind           = "StorageV2"
  private_endpoint = {
      virtual_network_resource_group = "vnet_rg_name"
      virtual_network_name           = "vnet_name"
      subnet_name                    = "pep_subnet_name"
  }
  replication_type = "LRS"
  tier             = "Standard"
}

# leave empty objects for resources you don't want to deploy (or just remove the corresponding .tf file)
sql_database = {
  # database_rg_name = "SQLTHANGDB"
  # server_name      = "SQLTHANG"
}

virtual_machine_list = {
  "windows-vm-db" = {
    data_disk_list                     = [
      {
        size_gb              = 150
        storage_account_type = "Premium_LRS"
      },
      {
        size_gb              = 150
        storage_account_type = "Premium_LRS"
      }
    ]
    function_code                      = "DB"
    ip_configuration = {
      virtual_network_resource_group = "vnet_rg_name"
      virtual_network_name           = "vnet_name"
      subnet_name                    = "db_subnet_name"
    }
    ordinal                            = "01"
    size                               = "Standard_D2ds_v5"
    source_image_publisher             = "MicrosoftWindowsServer"
    source_image_offer                 = "WindowsServer"
    source_image_sku                   = "2022-Datacenter"
    source_image_version               = "latest"
    vm_admin_credentials_secret_prefix = "vm-admin"
    vm_admin_name_prefix               = "xadmin"
  },
  "windows-vm-web" = {
    data_disk_list                     = [
      {
        size_gb              = 150
        storage_account_type = "Premium_LRS"
      },
      {
        size_gb              = 150
        storage_account_type = "Premium_LRS"
      }
    ]
    function_code                      = "WB"
    ip_configuration = {
      virtual_network_resource_group = "vnet_rg_name"
      virtual_network_name           = "vnet_name"
      subnet_name                    = "web_subnet_name"
    }
    ordinal                            = "01"
    size                               = "Standard_D4ds_v5"
    source_image_publisher             = "MicrosoftWindowsServer"
    source_image_offer                 = "WindowsServer"
    source_image_sku                   = "2022-Datacenter"
    source_image_version               = "latest"
    vm_admin_credentials_secret_prefix = "vm-admin"
    vm_admin_name_prefix               = "xadmin"
  }
}

web_app = {
  # app_service_slot_name              = "staging"
  # service_plan_name                  = "JRTFPOC-DEV-ASP"
  # service_environment_name           = "internal-ase-dev01"
  # service_environment_resource_group = "HQfoo-ENT-Network-DTP"
  # alert_action_group_name            = "Application Insights Smart Detection"
  # alert_action_group_rg_name         = "HQfoo-CCOE-53LISTSERVER-PROD"
}
