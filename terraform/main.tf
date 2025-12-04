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

# ---------------------------------------------------------------------------
# AVAILABLE REGIONS (Safe + Common + Multi-Geo)
# ---------------------------------------------------------------------------
locals {
  regions = [
    "eastus",
    "eastus2",
    "southcentralus",
    "centralus",
    "westus",
    "westus2",
    "westus3",
    "northeurope",
    "westeurope",
    "uksouth"
  ]

  vm_sizes = [
    "Standard_D2s_v3",  # 2 vCPU / 8GB RAM
    "Standard_D2as_v5",
    "Standard_D2ls_v5",
    "Standard_D2_v2"
  ]
}

# ---------------------------------------------------------------------------
# FIND FIRST WORKING REGION BY MAKE RG (try in sequence)
# ---------------------------------------------------------------------------

resource "azurerm_resource_group" "rg" {
  for_each = toset(local.regions)

  name     = "${var.prefix}-rg"
  location = each.key

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      name
    ]
  }

  depends_on = []
}

# Filter the first region that deployed successfully
locals {
  working_region = try(keys(azurerm_resource_group.rg)[0], null)
}

# ---------------------------------------------------------------------------
# NETWORKING (Using working_region)
# ---------------------------------------------------------------------------

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  location            = local.working_region
  resource_group_name = "${var.prefix}-rg"
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = "${var.prefix}-rg"
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "public_ip" {
  name                = "${var.prefix}-pip"
  resource_group_name = "${var.prefix}-rg"
  location            = local.working_region
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.prefix}-nic"
  location            = local.working_region
  resource_group_name = "${var.prefix}-rg"

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
# VM CREATION (Try VM sizes until one succeeds)
# ---------------------------------------------------------------------------

resource "azurerm_linux_virtual_machine" "vm" {
  for_each = toset(local.vm_sizes)

  name                = "${var.prefix}-vm"
  resource_group_name = "${var.prefix}-rg"
  location            = local.working_region

  size                = each.key
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

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      name
    ]
  }

  depends_on = [
    azurerm_network_interface.nic
  ]
}

# Pick first VM created
locals {
  working_vm_size = try(keys(azurerm_linux_virtual_machine.vm)[0], null)
}

# ---------------------------------------------------------------------------
# THE FINAL VM — SINGLE OUTPUT
# ---------------------------------------------------------------------------
output "region_used" {
  value = local.working_region
}

output "vm_size_used" {
  value = local.working_vm_size
}

output "public_ip" {
  value = azurerm_public_ip.public_ip.ip_address
}

output "private_key" {
  sensitive = true
  value     = tls_private_key.sshkey.private_key_pem
}
