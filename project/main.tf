terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
  }
  backend "azurerm" {
    resource_group_name  = "tfstate"
    storage_account_name = "tfstate1llwj"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
  required_version = ">= 0.12"
}

provider "azurerm" {
  features {}
  subscription_id = "be4d1a97-5702-4ad8-bcac-d4a969a1252e"
}

resource "azurerm_resource_group" "webhosting" {
    name = "static-web"
    location = "Central India"
}

resource "azurerm_virtual_network" "webhosting" {
    name = "new-network"
    address_space = ["10.0.0.0/16"]
    location = azurerm_resource_group.webhosting.location
    resource_group_name = azurerm_resource_group.webhosting.name
}


resource "azurerm_subnet" "webhosting" {
  name                 = "new-subnet"
  resource_group_name  = azurerm_resource_group.webhosting.name
  virtual_network_name = azurerm_virtual_network.webhosting.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "webhosting" {
  name                = "webhosting-public-ip"
  resource_group_name = azurerm_resource_group.webhosting.name
  location            = "Central India"
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "webhosting" {
  name                = "new-nic"
  location            = azurerm_resource_group.webhosting.location
  resource_group_name = azurerm_resource_group.webhosting.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.webhosting.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.webhosting.id
  }
}

resource "azurerm_network_security_group" "example" {
  name                = "example-nsg"
  location            = azurerm_resource_group.webhosting.location
  resource_group_name = azurerm_resource_group.webhosting.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}


resource "azurerm_virtual_machine" "webhosting" {
  name                  = "hosting-vm"
  location              = azurerm_resource_group.webhosting.location
  resource_group_name   = azurerm_resource_group.webhosting.name
  network_interface_ids = [azurerm_network_interface.webhosting.id]
  vm_size               = "Standard_B1s" # Adjust size as needed

  storage_os_disk {
    name              = "hosting-os-disk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"  
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "hosting-vm"
    admin_username = "azureuser"
    admin_password = "helloworld1!" # Replace with a secure password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}
