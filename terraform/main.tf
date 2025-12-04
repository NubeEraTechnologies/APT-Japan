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
# 1. REGION LIST (TEST ORDER)
# ---------------------------------------------------------------------------

locals {
  regions = [
    "eastus",
    "eastus2",
    "centralus",
    "southcentralus",
    "westus",
    "westus2",
    "westus3",
    "northeurope",
    "westeurope",
    "uksouth"
  ]

  vm_sizes = [
    "Standard_D2s_v3",
    "Standard_D2as_v5",
    "Standard_D2ls_v5",
    "Standard_D2_v2"
  ]
}

# ---------------------------------------------------------------------------
# 2. PROBE REGION AVAILABILITY BY CREATING TEMPORARY RGs
# ---------------------------------------------------------------------------

resource "azurerm_resource_group" "probe" {
  for_each = toset(local.regions)

  name     = "${var.prefix}-probe-${each.key}"
  location = each.key

  lifecycle {
    create_before_destroy = true
  }
}

# Choose first successfully created region
locals {
  working_region = keys(azurerm_resource_group.probe)[0]
}

# ---------------------------------------------------------------------------
# 3. REAL RESOURCE GROUP (CREATED ONCE)
# ---------------------------------------------------------------------------

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-rg"
  location = local.working_region
}

# ---------------------------------------------------------------------------
# 4. NETWORK RESOURCES
# ---------------------------------------------------------------------------

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet"
  location            = local.working_region
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
  location            = local.working_region
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "nic" {
  name                = "${var.prefix}-nic"
  location            = local.working_region
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.public_ip.id
  }
}

# ---------------------------------------------------------------------------
# 5. SSH KEY
# ---------------------------------------------------------------------------

resource "tls_private_key" "sshkey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# ---------------------------------------------------------------------------
# 6. VM CREATION – TRY EACH SIZE UNTIL ONE WORKS
# ---------------------------------------------------------------------------

resource "azurerm_linux_virtual_machine" "vm" {
  for_each = toset(local.vm_sizes)

  name                = "${var.prefix}-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = local.working_region
  size                = each.key

  admin_username = "azureuser"

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
  }

  depends_on = [
    azurerm_network_interface.nic
  ]
}

# Choose first VM that was created
locals {
  working_vm_size = keys(azurerm_linux_virtual_machine.vm)[0]
}

# ---------------------------------------------------------------------------
# 7. OUTPUTS
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
  value     = tls_private_key.sshkey.private_key_pem
  sensitive = true
}
