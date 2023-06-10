resource "azurerm_resource_group" "rg" {
  location = var.resource_group.location
  name     = upper("FOO-${var.application_info.app_name}-${var.application_info.environment}-RGP-${var.application_info.function}")
  tags     = var.resource_group.tags
}
