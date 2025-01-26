provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "elasticstack" {
  name     = "elasticstack-rg"
  location = var.azure_location
}

resource "azurerm_function_app" "elasticstack_function_app" {
  name                       = "elasticstack-function-app"
  location                   = azurerm_resource_group.elasticstack.location
  resource_group_name        = azurerm_resource_group.elasticstack.name
  app_service_plan_id        = azurerm_app_service_plan.elasticstack_service_plan.id
  storage_account_name       = azurerm_storage_account.elasticstack_storage.name
  storage_account_access_key = azurerm_storage_account.elasticstack_storage.primary_access_key
  version                    = "~3"
}

resource "azurerm_app_service_plan" "elasticstack_service_plan" {
  name                = "elasticstack-service-plan"
  location            = azurerm_resource_group.elasticstack.location
  resource_group_name = azurerm_resource_group.elasticstack.name
  kind                = "FunctionApp"
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_storage_account" "elasticstack_storage" {
  name                     = "elasticstackstorage"
  resource_group_name      = azurerm_resource_group.elasticstack.name
  location                 = azurerm_resource_group.elasticstack.location
  account_tier              = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_blob" "function_code_blob" {
  name                   = "function-code.zip"
  storage_account_name   = azurerm_storage_account.elasticstack_storage.name
  storage_container_name = "function-code-container"
  type                   = "Block"
  source                 = "function-code.zip"  # Path to your zipped function code
}

# Output the Function App URL for convenience
output "function_app_url" {
  description = "URL of the Azure Function App"
  value       = azurerm_function_app.elasticstack_function_app.default_site_hostname
}

# Define variables
variable "azure_location" {
  description = "Azure region for resources"
  default     = "East US"
}

variable "azure_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "azure_resource_group" {
  description = "Resource Group Name"
  type        = string
}

variable "azure_vm_name" {
  description = "The name of the Azure VM to scale"
  type        = string
}

variable "azure_metric_name" {
  description = "The metric name to scale based on (e.g., NetworkIn, CPUUtilization)"
  default     = "NetworkIn"
}

variable "azure_scale_up_threshold" {
  description = "The threshold for scaling up"
  default     = 50
}

variable "azure_scale_down_threshold" {
  description = "The threshold for scaling down"
  default     = 10
}