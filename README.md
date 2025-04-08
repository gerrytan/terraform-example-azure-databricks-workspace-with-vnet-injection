# terraform-example-azure-databricks-vnet-injection

An example of Terraform configuration to setup an Azure Databricks workspace
with [VNet
injection](https://learn.microsoft.com/en-us/azure/databricks/security/network/classic/vnet-inject).

All of the `security_rule` blocks on `azurerm_network_security_group` are those
that will be automatically configured by Databricks on the VNet. Without these,
the next terraform plan will have a drift.
