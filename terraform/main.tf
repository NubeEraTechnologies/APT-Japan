provider "azurerm" {
  features {}
  subscription_id = "bd65aea3-75fe-4024-8c52-185c16367c34"
}

# Variables
variable "prefix" { default = "devvm" }
variable "location" { default = "eastus" }

data "azurerm_compute_resource_skus" "all" {}

locals {
  required_vm_skus = [
    "Standard_D2s_v3",
    "Standard_D2as_v5",
    "Standard_D2ls_v5"
  ]

  filtered_skus = [
    for sku in data.azurerm_compute_resource_skus.all.resource_skus :
    sku.name if contains(local.required_vm_skus, sku.name)
  ]

  chosen_vm_sku = length(local.filtered_skus) > 0 ? local.filtered_skus[0] : "Standard_D2s_v3"

  chosen_region = [
    for sku in data.azurerm_compute_resource_skus.all.resource_skus :
    sku.locations[0] if sku.name == local.chosen_vm_sku
  ][0]
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = local.chosen_region
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "public_ip" {
  name                = "${var.prefix}-pip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# SSH key
resource "tls_private_key" "sshkey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "${var.prefix}-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"

  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.sshkey.public_key_openssh
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  # 🔥 REQUIRED BLOCK (missing before — caused your error)
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}

# Output for Ansible
output "public_ip" {
  value = azurerm_public_ip.public_ip.ip_address
}

output "private_key" {
  value     = tls_private_key.sshkey.private_key_pem
  sensitive = true
}
