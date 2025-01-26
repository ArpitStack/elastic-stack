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
