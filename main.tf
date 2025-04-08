terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "prefix" {
  type = string
}

variable "location" {
  type = string
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = var.location
}

# VNet ---------------------------------------

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

# Public subnet ---------------------------------------

resource "azurerm_subnet" "public" {
  address_prefixes     = ["10.0.0.0/24"]
  name                 = "${var.prefix}-dbw-public"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name

  delegation {
    name = "databricks_delegation"

    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
      ]
    }
  }
}

resource "azurerm_network_security_group" "public" {
  name                = "${var.prefix}-nsgpub"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    access                     = "Allow"
    description                = "Required for worker communication with Azure Eventhub services."
    destination_address_prefix = "EventHub"
    destination_port_range     = "9093"
    direction                  = "Outbound"
    name                       = "Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-eventhub"
    priority                   = 104
    protocol                   = "Tcp"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
  }
  security_rule {
    access                     = "Allow"
    description                = "Required for worker nodes communication within a cluster."
    destination_address_prefix = "VirtualNetwork"
    destination_port_range     = "*"
    direction                  = "Inbound"
    name                       = "Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-worker-inbound"
    priority                   = 100
    protocol                   = "*"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
  }
  security_rule {
    access                     = "Allow"
    description                = "Required for worker nodes communication within a cluster."
    destination_address_prefix = "VirtualNetwork"
    destination_port_range     = "*"
    direction                  = "Outbound"
    name                       = "Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-worker-outbound"
    priority                   = 100
    protocol                   = "*"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
  }
  security_rule {
    access                     = "Allow"
    description                = "Required for workers communication with Azure SQL services."
    destination_address_prefix = "Sql"
    destination_port_range     = "3306"
    direction                  = "Outbound"
    name                       = "Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-sql"
    priority                   = 102
    protocol                   = "Tcp"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
  }
  security_rule {
    access                     = "Allow"
    description                = "Required for workers communication with Azure Storage services."
    destination_address_prefix = "Storage"
    destination_port_range     = "443"
    direction                  = "Outbound"
    name                       = "Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-storage"
    priority                   = 103
    protocol                   = "Tcp"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
  }
  security_rule {
    access                     = "Allow"
    description                = "Required for workers communication with Databricks control plane."
    destination_address_prefix = "AzureDatabricks"
    destination_port_ranges = [
      "3306",
      "443",
      "8443-8451",
    ]
    direction             = "Outbound"
    name                  = "Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-databricks-webapp"
    priority              = 101
    protocol              = "Tcp"
    source_address_prefix = "VirtualNetwork"
    source_port_range     = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "public" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.public.id
}

# Private subnet ---------------------------------------

resource "azurerm_subnet" "private" {
  address_prefixes     = ["10.0.1.0/24"]
  name                 = "${var.prefix}-dbw-private"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name

  delegation {
    name = "databricks_delegation"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
      ]
    }
  }
}

resource "azurerm_network_security_group" "private" {
  name                = "${var.prefix}-nsgpriv"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    access                     = "Allow"
    description                = "Required for worker communication with Azure Eventhub services."
    destination_address_prefix = "EventHub"
    destination_port_range     = "9093"
    direction                  = "Outbound"
    name                       = "Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-eventhub"
    priority                   = 104
    protocol                   = "Tcp"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
  }
  security_rule {
    access                     = "Allow"
    description                = "Required for worker nodes communication within a cluster."
    destination_address_prefix = "VirtualNetwork"
    destination_port_range     = "*"
    direction                  = "Inbound"
    name                       = "Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-worker-inbound"
    priority                   = 100
    protocol                   = "*"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
  }
  security_rule {
    access                     = "Allow"
    description                = "Required for worker nodes communication within a cluster."
    destination_address_prefix = "VirtualNetwork"
    destination_port_range     = "*"
    direction                  = "Outbound"
    name                       = "Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-worker-outbound"
    priority                   = 100
    protocol                   = "*"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
  }
  security_rule {
    access                     = "Allow"
    description                = "Required for workers communication with Azure SQL services."
    destination_address_prefix = "Sql"
    destination_port_range     = "3306"
    direction                  = "Outbound"
    name                       = "Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-sql"
    priority                   = 102
    protocol                   = "Tcp"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
  }
  security_rule {
    access                     = "Allow"
    description                = "Required for workers communication with Azure Storage services."
    destination_address_prefix = "Storage"
    destination_port_range     = "443"
    direction                  = "Outbound"
    name                       = "Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-storage"
    priority                   = 103
    protocol                   = "Tcp"
    source_address_prefix      = "VirtualNetwork"
    source_port_range          = "*"
  }
  security_rule {
    access                     = "Allow"
    description                = "Required for workers communication with Databricks control plane."
    destination_address_prefix = "AzureDatabricks"
    destination_port_ranges = [
      "3306",
      "443",
      "8443-8451",
    ]
    direction             = "Outbound"
    name                  = "Microsoft.Databricks-workspaces_UseOnly_databricks-worker-to-databricks-webapp"
    priority              = 101
    protocol              = "Tcp"
    source_address_prefix = "VirtualNetwork"
    source_port_range     = "*"
  }

}

resource "azurerm_subnet_network_security_group_association" "private" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.private.id
}


# Workspace ---------------------------------------

resource "azurerm_databricks_workspace" "dbw" {
  name                        = "${var.prefix}-dbw"
  resource_group_name         = azurerm_resource_group.rg.name
  sku                         = "premium"
  location                    = azurerm_resource_group.rg.location
  managed_resource_group_name = "${var.prefix}-dbw-rg"

  custom_parameters {
    virtual_network_id                                   = azurerm_virtual_network.vnet.id
    public_subnet_name                                   = azurerm_subnet.public.name
    private_subnet_name                                  = azurerm_subnet.private.name
    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.public.id
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.private.id
  }
}
