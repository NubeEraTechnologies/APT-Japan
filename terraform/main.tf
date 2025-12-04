provider "azurerm" {
  features {}
  subscription_id = "bd65aea3-75fe-4024-8c52-185c16367c34"
}

terraform {
  required_version = ">= 1.1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

variable "prefix" {
  default = "devvm"
}

variable "region" {
  default = "eastus2"
}

variable "vm_size" {
  default = "Standard_B2s"  # change to Standard_D2s_v3 if you want 8GB RAM
}

# ---------------------------------------------------------------------------
# RESOURCE GROUP
# ---------------------------------------------------------------------------
resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = var.region
}

# ---------------------------------------------------------------------------
# VIRTUAL NETWORK + SUBNET
# ---------------------------------------------------------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# ---------------------------------------------------------------------------
# PUBLIC IP (Standard + Static)
# ---------------------------------------------------------------------------
resource "azurerm_public_ip" "public_ip" {
  name                = "${var.prefix}-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.region
  allocation_method   = "Static"
  sku                 = "Standard"
}

# ---------------------------------------------------------------------------
# NETWORK INTERFACE
# ---------------------------------------------------------------------------
resource "azurerm_network_interface" "nic" {
  name                = "${var.prefix}-nic"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# ---------------------------------------------------------------------------
# SSH KEY
# ---------------------------------------------------------------------------
resource "tls_private_key" "sshkey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# ---------------------------------------------------------------------------
# VIRTUAL MACHINE
# ---------------------------------------------------------------------------
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "${var.prefix}-vm"
  location            = var.region
  resource_group_name = azurerm_resource_group.rg.name

  size                = var.vm_size
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.sshkey.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

# ---------------------------------------------------------------------------
# OUTPUTS
# ---------------------------------------------------------------------------
output "public_ip" {
  value = azurerm_public_ip.public_ip.ip_address
}

output "private_key" {
  value     = tls_private_key.sshkey.private_key_pem
  sensitive = true
}

output "vm_size" {
  value = var.vm_size
}

output "region" {
  value = var.region
}
