
provider "azurerm" {
  # subscription_id = "${var.subscription_id}"
  # client_id       = "${var.client_id}"
  # client_secret   = "${var.client_secret}"
  # tenant_id       = "${var.tenant_id}"
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.projectPrefix}-f5-xc"
  location = var.location
}


resource "azurerm_network_security_group" "f5-xc-nsg" {
  name                = "f5_xc_nsg"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
}


resource "azurerm_network_security_rule" "f5-xc-nsg-rule" {
  name                        = "allow_trusted"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = var.trusted_ip
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.f5-xc-nsg.name
}

resource "azurerm_network_security_rule" "f5-xc-nsg-rule2" {
  name                        = "allow_trusted"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "10.0.0.0/8"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.f5-xc-nsg.name
}


resource "azurerm_network_security_rule" "block_dns" {
  name                        = "block_dns"
  priority                    = 150
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "53"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.f5-xc-nsg.name
}

resource "azurerm_network_security_rule" "allow_dns" {
  name                        = "allow_dns"
  priority                    = 149
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "53"
  source_address_prefix       = "10.0.0.0/8"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.f5-xc-nsg.name
}



resource "azurerm_virtual_network" "f5-xc-hub" {
  name                = "f5_xc_hub_vnet"
  location            = var.location
  address_space       = [var.servicesVnetAddressSpace]
  resource_group_name = azurerm_resource_group.rg.name
}


resource "azurerm_subnet" "external" {
  name                 = "external_subnet"
  virtual_network_name = azurerm_virtual_network.f5-xc-hub.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = [var.servicesVnetExternalSubnet]
}

resource "azurerm_subnet" "internal" {
  name                 = "internal_subnet"
  virtual_network_name = azurerm_virtual_network.f5-xc-hub.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = [var.servicesVnetInternalSubnet]
}

resource "azurerm_subnet" "workload" {
  name                 = "workload_subnet"
  virtual_network_name = azurerm_virtual_network.f5-xc-hub.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = [var.servicesVnetWorkloadSubnet]
}

resource "azurerm_route_table" "workload" {
  name                = "workload_rt"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet_route_table_association" "workload" {
  subnet_id      = azurerm_subnet.workload.id
  route_table_id = azurerm_route_table.workload.id
}

resource "azurerm_subnet_network_security_group_association" "f5-xc" {
  subnet_id                 = azurerm_subnet.external.id
  network_security_group_id = azurerm_network_security_group.f5-xc-nsg.id
}