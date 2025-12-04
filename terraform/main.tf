provider "azurerm" {
  features {}
  subscription_id = "bd65aea3-75fe-4024-8c52-185c16367c34"
}
terraform {
  required_version = ">= 1.4.0"

variable "prefix" {
  default = "devvm"
}

# ---------------------------------------------------------------------------
# DATA SOURCES — AUTO DISCOVER REGIONS + VM SIZES
# ---------------------------------------------------------------------------

data "azurerm_compute_resource_skus" "all" {}

locals {
  # VM sizes you prefer (2 vCPU + ~8 GB RAM)
  required_vm_skus = [
    "Standard_D2s_v3",   # 2 vCPU, 8GB (common)
    "Standard_D2as_v5",  # 2 vCPU, 8GB (new gen)
    "Standard_D2ls_v5"   # 2 vCPU, 8GB (low cost)
  ]

  # Filter SKUs available in this subscription
  filtered_skus = [
    for sku in data.azurerm_compute_resource_skus.all.resource_skus :
    sku.name
    if contains(local.required_vm_skus, sku.name)
  ]

  # Choose first available size
  chosen_vm_sku = length(local.filtered_skus) > 0 ? local.filtered_skus[0] : "Standard_D2s_v3"

  # Select a region where this SKU is available
  chosen_region = [
    for sku in data.azurerm_compute_resource_skus.all.resource_skus :
    sku.locations[0]
    if sku.name == local.chosen_vm_sku
  ][0]
}

# ---------------------------------------------------------------------------
# RESOURCE GROUP
# ---------------------------------------------------------------------------

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = local.chosen_region
}

# ---------------------------------------------------------------------------
# NETWORKING
# ---------------------------------------------------------------------------

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

# Standard Public IP (Static required)
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

# ---------------------------------------------------------------------------
# SSH KEY
# ---------------------------------------------------------------------------

resource "tls_private_key" "sshkey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# ---------------------------------------------------------------------------
# LINUX VM
# ---------------------------------------------------------------------------

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "${var.prefix}-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  size                = local.chosen_vm_sku     # Auto-selected size
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.nic.id
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.sshkey.public_key_openssh
  }

  # Required OS disk block
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

output "vm_size_selected" {
  value = local.chosen_vm_sku
}

output "region_selected" {
  value = local.chosen_region
}

output "private_key" {
  value     = tls_private_key.sshkey.private_key_pem
  sensitive = true
}
