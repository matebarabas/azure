# This sample template creates an azurerm_virtual_machine
# See more details on https://www.terraform.io/docs/providers/azurerm/r/virtual_machine.html


###########################################################################################################
# PROVIDERS
###########################################################################################################
provider "azurerm" {
  version         = "~>1.27"
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
  tenant_id       = "${var.tenant_id}"
}


###########################################################################################################
# BACKEND (REMOTE STATE)
###########################################################################################################
terraform {
  backend "azurerm" {
    storage_account_name = ""
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
    access_key           = ""
  }
}


###########################################################################################################
# VARIABLES
###########################################################################################################
# ID of the Azure Subscription this configuration is targeted against (e.g. 6a0a87c2-426f-b854-aab8-21041f09f06b)
variable "subscription_id" {
  default = ""
}

# ID of the Service principal used to access the target Azure Subscription (e.g. 23e5a3bf-426f-b854-aab8-21041f09f06b)
variable "client_id" {
  default = ""
}

# Secret value of the Service principal used to access tthe target Azure Subscription(e.g. 9c0a87c2-426f-b854-aab8-21041f09f06b)
variable "client_secret" {
  default = ""
}

# ID of the Azure AD tenant used for authenticating to the target Azure Subscription (e.g. 6a0a87c2-426f-b854-aab8-21041f09f06b)
variable "tenant_id" {
  default = ""
}

# Naming prefix
variable "prefix" {
  default = "tf-test"
}

###########################################################################################################
# RESOURCES
###########################################################################################################

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = "West US 2"
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = "${azurerm_resource_group.main.name}"
  virtual_network_name = "${azurerm_virtual_network.main.name}"
  address_prefix       = "10.0.2.0/24"
}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = "${azurerm_resource_group.main.location}"
  resource_group_name = "${azurerm_resource_group.main.name}"

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = "${azurerm_subnet.internal.id}"
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-vm"
  location              = "${azurerm_resource_group.main.location}"
  resource_group_name   = "${azurerm_resource_group.main.name}"
  network_interface_ids = ["${azurerm_network_interface.main.id}"]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true


  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}