## Terraform HandsOn Lab

## ***Agenda***

***1. Prepare Tools & Setup***  
***2. Authentication To Azure***  
***3. Create 1st .tf file***  
***4. Generate a resource graph***  
***5. Deploy an Azure VM***  
***6. Attach Managed Disk to Azure VM***  
***7. Modify Managed Disk Size***  
***8. Unattach and Delete Managed Disk***  
***9. Destroy All Resource***  


### 1. Prepare Tools & Setup
+ **Terraform**
```
https://www.terraform.io/downloads
```
**terraform_1.1.7_windows_amd64.zip** in Channel Files 

+ **graphviz**
```
http://www.graphviz.org/Download_windows.php
```
**windows_10_cmake_Release_graphviz-install-3.0.0-win64.exe** in Channel Files 

+ **VSCode**
```
https://code.visualstudio.com/
```
**VSCodeUserSetup-x64-1.65.2.exe** in Channel Files 

+ **Terraform Visual Studio Code Extension**
```
VSCode Extension Feature
```
**HashiCorp.terraform-2.21.0@win32-x64.vsix** in Channel Files 

### 2. Authentication To Azure
+ Azure CLI  
```
https://docs.microsoft.com/zh-cn/cli/azure/install-azure-cli-windows?tabs=azure-cli
```
**azure-cli-2.34.1.msi** in Channel Files  
AZ Login  

+ Service Principal  

App Registrations create a new application,Assign permission to the Application.     
Create batch file named 'terraform_env.bat' content as follow
```
set ARM_SUBSCRIPTION_ID=your_subscription_id
set ARM_CLIENT_ID=your_appId
set ARM_CLIENT_SECRET=your_password
set ARM_TENANT_ID=your_tenant_id	
set	ARM_ENVIRONMENT=public
```

### 3. Create 1st .tf file
create a .tf file in workspace, Declare a provider and a resource group in .tf file.  

```
provider "azurerm" {
  features {
    
  }
}

resource "azurerm_resource_group" "rg" {
  name="TfTestResourceGroup"
  location = "eastasia"
}
```

open cmd and change work directory to workspace.

use command 'init' initialze terraform modules  
```
terraform init
```
use command 'plan' verify execution plan, it can show operation details. 
```
terraform plan
```
use command 'apply' execute deployment, create resource group.
```
terraform apply -auto-approve
```

### 4. Generate a resource graph
use command 'graph' generate a dot data, and command 'dot' export to a .svg file.

```
terraform graph | dot -Tsvg > graph.svg
```


### 5. Deploy an Azure VM
+ Deploy VNet and Subnet  

append VNet and SubNet declaration to .tf file.

```
resource "azurerm_virtual_network" "vnet" {
    name                = "TfTestVnet"
    address_space       = ["10.0.0.0/16"]
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
    name                 = "TfTestSubnet"
    resource_group_name  = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes       = ["10.0.1.0/24"]
}
```

use command 'apply' execute deployment, create VNet and SubNet.

```
terraform apply -auto-approve
```

+ Deploy Public IP

append Public IP declaration to .tf file.
```
resource "azurerm_public_ip" "pip" {
    name                         = "TfTestPublicIP"
    location                     = azurerm_resource_group.rg.location
    resource_group_name          = azurerm_resource_group.rg.name
    allocation_method            = "Dynamic"
}
```

use command 'apply' execute deployment, create Public IP.

```
terraform apply -auto-approve
```

+ Deploy Network Security Group  

append Network Security Group declaration to .tf file.
```
resource "azurerm_network_security_group" "nsg" {
    name                = "TfTestNetworkSecurityGroup"
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name

    security_rule {
        name                       = "RDP"
        priority                   = 500
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "3389"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}
```


use command 'apply' execute deployment, create Network Security Group.

```
terraform apply -auto-approve
```


+ Deploy Network Interface Controller  

append Network Interface Controller declaration to .tf file.

```
resource "azurerm_network_interface" "nic" {
    name                      = "TfTestNIC"
    location                  = azurerm_resource_group.rg.location
    resource_group_name       = azurerm_resource_group.rg.name

    ip_configuration {
        name                          = "TfTestNicConfiguration"
        subnet_id                     = azurerm_subnet.subnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.pip.id
    }
}
```

use command 'apply' execute deployment, create Network Interface Controller.

```
terraform apply -auto-approve
```

+ Associate Network interface and Security Group

append Network interface and Security Group association declaration to .tf file.

```
resource "azurerm_network_interface_security_group_association" "if_nsg_assc" {
    network_interface_id      = azurerm_network_interface.nic.id
    network_security_group_id = azurerm_network_security_group.nsg.id
}
```

use command 'apply' execute deployment, create Network interface and Security Group association.

```
terraform apply -auto-approve
```

+ Deploy Virtual Machine
 
append Virtual Machine declaration to .tf file.

```
resource "azurerm_windows_virtual_machine" "winvm" {
  name                = "TfTestWinVM"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_F2"
  admin_username      = "vm-admin"
  admin_password      = "+123QWEasd"
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}
```
use command 'apply' execute deployment, create Virtual Machine.

```
terraform apply -auto-approve
```


### 6. Attach Managed Disk to Azure VM
+ Deploy Managed Disk

append Managed Disk declaration to .tf file.

```
resource "azurerm_managed_disk" "disk" {
  name                 = "${azurerm_windows_virtual_machine.winvm.name}-disk1"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 10
}
```

use command 'apply' execute deployment, create Managed Disk.

```
terraform apply -auto-approve
```

+ Attach Managed Disk to VM

append Attach Managed Disk declaration to .tf file.
```
resource "azurerm_virtual_machine_data_disk_attachment" "vm_disk_assc" {
  managed_disk_id    = azurerm_managed_disk.disk.id
  virtual_machine_id = azurerm_windows_virtual_machine.winvm.id
  lun                = "10"
  caching            = "ReadWrite"
}
```

use command 'apply' execute deployment, create Attach Managed Disk association.

```
terraform apply -auto-approve
```

### 7. Modify Managed Disk Size

change property 'disk_size_gb' To 15 in Managed Disk declaration.
```
resource "azurerm_managed_disk" "disk" {
  name                 = "${azurerm_windows_virtual_machine.winvm.name}-disk1"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 15
}
```

use command 'apply' execute deployment, modify Managed Disk size property.

```
terraform apply -auto-approve
```

### 8. Unattach and Delete Managed Disk
+ Unattach managed disk from Azure VM  

Remove follow association declaration from .tf file.
```
resource "azurerm_virtual_machine_data_disk_attachment" "vm_disk_assc" {
  managed_disk_id    = azurerm_managed_disk.disk.id
  virtual_machine_id = azurerm_windows_virtual_machine.winvm.id
  lun                = "10"
  caching            = "ReadWrite"
}
```

use command 'apply' execute deployment, delete association managed disk and Azure VM.

```
terraform apply -auto-approve
```


+ Delete managed disk  

Remove follow resource declaration from .tf file, and use command 'apply' execute deployment.
```
resource "azurerm_managed_disk" "disk" {
  name                 = "${azurerm_windows_virtual_machine.winvm.name}-disk1"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 15
}
```

use command 'apply' execute deployment, delete managed disk.

```
terraform apply -auto-approve
```

### 9. Destroy All Resources

use command 'destroy' execute deployment, delete all resources.

```
terraform destroy
```
