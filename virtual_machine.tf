resource "azurerm_availability_set" "as" {
  for_each = var.virtual_machine_list

  location                     = azurerm_resource_group.rg.location
  name                         = upper("FOO-${var.application_info.app_name}-${var.application_info.environment}-AVS-${each.key}")
  platform_fault_domain_count  = each.value.availability_set_platform_fault_domain_count
  platform_update_domain_count = each.value.availability_set_platform_update_domain_count
  resource_group_name          = azurerm_resource_group.rg.name
}

locals {
  vm_data_disk_list = flatten([
    for vm_key, vm in var.virtual_machine_list : [
      for disk_key, disk in vm.data_disk_list : {
        disk_key             = disk_key
        vm_key               = vm_key
        size_gb              = disk.size_gb
        storage_account_type = disk.storage_account_type
      }
    ]
  ])
}

resource "azurerm_managed_disk" "datadisk" {
  for_each = {
    for disk in local.vm_data_disk_list : "${disk.vm_key}-${disk.disk_key}" => disk
  }

  create_option        = "Empty"
  disk_size_gb         = each.value.size_gb
  location             = azurerm_resource_group.rg.location
  name                 = upper("FOO-${var.application_info.app_name}-${var.application_info.environment}-DDS-${each.key}")
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = each.value.storage_account_type
}

data "azurerm_subnet" "vm_subnet" {
  for_each = {
    for vm_key, vm in var.virtual_machine_list : vm_key => vm.ip_configuration
  }

  name                 = each.value.subnet_name
  virtual_network_name = each.value.virtual_network_name
  resource_group_name  = each.value.virtual_network_resource_group
}

resource "azurerm_network_interface" "nic" {
  for_each = var.virtual_machine_list

  location            = azurerm_resource_group.rg.location
  name                = upper("FOO-${var.application_info.app_name}-${var.application_info.environment}-NIC-${each.key}")
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = upper("FOO-${var.application_info.app_name}-${var.application_info.environment}-NCG-${each.key}")
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = data.azurerm_subnet.vm_subnet[each.key].id
  }
}

resource "azurerm_windows_virtual_machine" "list" {
  for_each = { 
    for vmname, vm in var.virtual_machine_list : vmname => vm
    if vm.source_image_offer == "WindowsServer"
  }

  admin_username        = azurerm_key_vault_secret.vm_admin_name[each.key].value
  admin_password        = azurerm_key_vault_secret.vm_admin_password[each.key].value
  availability_set_id   = azurerm_availability_set.as[each.key].id
  location              = azurerm_resource_group.rg.location
  name                  = upper("ABC${var.application_info.project}${var.application_info.UIC}${each.value.function_code}${var.application_info.environment}${each.value.ordinal}")
  network_interface_ids = [
    azurerm_network_interface.nic[each.key].id
  ]
  resource_group_name = azurerm_resource_group.rg.name
  size                = each.value.size

  identity {
    type = "SystemAssigned"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    offer     = each.value.source_image_offer
    publisher = each.value.source_image_publisher
    sku       = each.value.source_image_sku
    version   = each.value.source_image_version
  }
}

resource "azurerm_virtual_machine_data_disk_attachment" "list" {
  for_each = {
    for disk in local.vm_data_disk_list : "${disk.vm_key}-${disk.disk_key}" => disk
  }

  caching            = "None"
  create_option      = "Empty"
  lun                = each.value.disk_key
  managed_disk_id    = azurerm_managed_disk.datadisk[each.key].id
  virtual_machine_id = azurerm_windows_virtual_machine.list[each.value.vm_key].id
}

resource "azurerm_virtual_machine_extension" "list" {
  for_each = var.virtual_machine_list

  auto_upgrade_minor_version = true
  name                       = "joindomain"
  publisher                  = "Microsoft.Compute"
  settings                   = "{\"Name\":\"foo.army.mil\",\"OUPath\":\"\",\"Options\":3,\"Restart\":\"true\",\"User\":\"foo\\\\service_account_name\"}"
  type                       = "JsonADDomainExtension"
  type_handler_version       = "1.3"
  virtual_machine_id         = azurerm_windows_virtual_machine.list[each.key].id
}
