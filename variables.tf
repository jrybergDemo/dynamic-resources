### Azure Resource Name Restrictions
# Source: https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/resource-name-rules

variable "application_info" {
  type        = object({
    app_name    = string
    environment = string
    function    = string
    project     = string
    UIC         = string
  })
  description = "Describes the various required components of the application being deployed. Used as the basis for dynamically naming resources"

  validation {
    condition     = can(regex("[DTP]", var.application_info.environment)) && can(regex("^[a-zA-Z0-9]{1}$", var.application_info.project)) && can(regex("^[a-zA-Z0-9]{6}$", var.application_info.UIC))
    error_message = "Environment accepts 'D', 'T', or 'P' only. Project must be 1 alphanumeric. UIC must be 6 alphanumerics."
  }
}

variable "backup_services" {
  type        = bool
  description = "If set to true, a recovery services vault will be deployed with associated policies for VMs & SQL DB."
}

variable "domain_join" {
  type = object({
    domain_fqdn = string
    ou_path     = optional(string)
    username    = string
  })
}

variable "resource_group" {
  type = object({
    location = string
    tags     = map(string)
  })
}

### Storage Account Restrictions
# Length between 3 and 24 characters with only lowercase letters and numbers.
# Note: Must be globally unique across Azure. Storage account names can't be duplicated in Azure.
# Source: https://learn.microsoft.com/en-us/azure/storage/common/storage-account-overview#storage-account-name
variable "storage_account" {
  type = object({
    kind             = string
    container_name   = string
    replication_type = string
    tier             = string
    private_endpoint = object({
      virtual_network_name           = string
      virtual_network_resource_group = string
      subnet_name                    = string
    })
  })
}

variable "sql_database" {
  type = object({
    database_rg_name = optional(string)
    server_name      = optional(string)
  })
}

variable "virtual_machine_list" {
  type = map(object({
    availability_set_platform_fault_domain_count  = number
    availability_set_platform_update_domain_count = number
    data_disk_list                                = list(object({
      size_gb              = number
      storage_account_type = string
    }))
    function_code                                 = string
    ip_configuration = object({
      virtual_network_resource_group = string
      virtual_network_name           = string
      subnet_name                    = string
    })
    ordinal                                       = string
    size                                          = string
    source_image_publisher                        = string
    source_image_offer                            = string
    source_image_sku                              = string
    source_image_version                          = string
    vm_admin_credentials_secret_prefix            = string
    vm_admin_name_prefix                          = string
  }))
}

variable "web_app" {
  type = object({
    app_service_slot_name              = optional(string)
    service_plan_name                  = optional(string)
    service_environment_name           = optional(string)
    service_environment_resource_group = optional(string)
    alert_action_group_name            = optional(string)
    alert_action_group_rg_name         = optional(string)
  })
}
