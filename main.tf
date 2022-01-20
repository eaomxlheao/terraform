resource "azurerm_resource_group" "rg" {
  name     = "eao"
  location = "West Europe"

  tags = {
    environment = "Terraform Azure"
  }
}

resource "azurerm_network_watcher" "nwwatcher" {
  name                = "eao-nwwatcher"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_virtual_network" "vnet" {
  name                = "eao-vnet"
  location            = "West Europe"
  address_space       = ["10.0.0.0/16"]
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "eao-subnet"
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = azurerm_resource_group.rg.name
  address_prefixes     = ["10.0.10.0/24"]
}

resource "azurerm_network_interface" "nic" {
  name                = "eao-nic"
  location            = "West Europe"
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "eaoipconfig"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_public_ip" "pip" {
  name                         = "eap-pip"
  location                     = "West Europe"
  allocation_method            = "Static"
  resource_group_name          = azurerm_resource_group.rg.name
  domain_name_label            = "eaodevops"
}

resource "azurerm_storage_account" "stor" {
  name                     = "eaostorage"
  location                 = "West Europe"
  resource_group_name      = azurerm_resource_group.rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_virtual_machine" "vm" {
  name                  = "eaovm"
  location              = "West Europe"
  resource_group_name   = azurerm_resource_group.rg.name
  vm_size               = "Standard_DS1_v2"
  network_interface_ids = [azurerm_network_interface.nic.id]

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "eao-osdisk"
    managed_disk_type = "Standard_LRS"
    caching           = "ReadWrite"
    create_option     = "FromImage"
  }

  os_profile {
    computer_name  = "EAOVM"
    admin_username = "eaomxlheao"
    admin_password = "Moquito1"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  boot_diagnostics {
    enabled     = true
    storage_uri = azurerm_storage_account.stor.primary_blob_endpoint
  }
}
