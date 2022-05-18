## Azure Terraform Hands-On Lab

### **目录**
#### 第一部分 Azure Terraform开发 
***1.1 工具准备及安装***  
***1.2 Azure权限验证***  
***1.3 创建变量文件***  
***1.4 创建配置文件***  
***1.5 生成资源图表***  
***1.6 部署Azure虚拟机***  
***1.7 为虚拟机附加托管磁盘***  
***1.8 修改托管磁盘容量***  
***1.9 分离与删除托管磁盘***  
***1.10 销毁全部资源***  

#### 第二部分 GitHub Actions实现Azure Terraform自动化部署  

***2.1 创建GitHub Secrets***  
***2.2 开发workflows yaml文件***  
***2.3 运行workflows***  

---
### 第一部分 Azure Terraform开发 
### 1.1 工具准备及安装
+ **Terraform**
```
https://www.terraform.io/downloads
```
可以在以下地址获取 **terraform_1.1.7_windows_amd64.zip**   
[https://github.com/contosoms/ACAI-ACF-Training/tree/main/software](https://github.com/contosoms/ACAI-ACF-Training/tree/main/software)

解压并设置Path环境变量。 

+ **graphviz**
```
http://www.graphviz.org/Download_windows.php
```
可以在以下地址获取 **windows_10_cmake_Release_graphviz-install-3.0.0-win64.exe**    
[https://github.com/contosoms/ACAI-ACF-Training/tree/main/software](https://github.com/contosoms/ACAI-ACF-Training/tree/main/software) 

解压并设置Path环境变量。 

+ **VSCode**
```
https://code.visualstudio.com/
```
可以在以下地址获取 **VSCodeUserSetup-x64-1.65.2.exe**   
[https://github.com/contosoms/ACAI-ACF-Training/tree/main/software](https://github.com/contosoms/ACAI-ACF-Training/tree/main/software)

双击文件安装。  

+ **Terraform Visual Studio Code Extension**
```
VSCode Extension Feature
```
可以在以下地址获取 **HashiCorp.terraform-2.21.0@win32-x64.vsix**    
[https://github.com/contosoms/ACAI-ACF-Training/tree/main/software](https://github.com/contosoms/ACAI-ACF-Training/tree/main/software)

运行 vscode, 点击左侧菜单中的 extension 功能, 通过在线或离线的方式安装扩展组件。  

### 1.2 Azure权限验证
+ Azure CLI  
```
https://docs.microsoft.com/zh-cn/cli/azure/install-azure-cli-windows?tabs=azure-cli
```
可以在以下地址获取 **azure-cli-2.34.1.msi**   

[https://github.com/contosoms/ACAI-ACF-Training/tree/main/software](https://github.com/contosoms/ACAI-ACF-Training/tree/main/software)  
```
AZ Login  
```

+ Service Principal  
应用注册创建一个新的应用, 并为应用分配权限。  
> 登录 **Microsoft Azure Portal** 并 选择 **Azure活动目录**, 在左侧菜单中点击 **应用注册**, 并使用 **新注册** 功能创建新的 Service Principal。

> 登录 **Microsoft Azure Portal** 并 选择 **订阅**, 在左侧菜单中点击 **访问控制(标识和访问管理)** 并分配 **Contributor** 的角色给上一个步骤中创建的Service Principal对象。  

> 使用下面的命令与 **Microsoft Azure Portal** 操作效果相同, 创建服务主体并配置其对 Azure 资源的访问权限。
```
az ad sp create-for-rbac --name "myApp" --role contributor --scopes /subscriptions/{subscription-id}
az login --service-principal -u $AZURE_CLIENT_ID -p $AZURE_CLIENT_SECRET -t $AZURE_TENANT_ID
```
在Terraform项目根目录创建examples目录。  

在examples目录下创建批处理文件 'terraform_env.bat', 并将Azure Service Principle的凭据设置为环境变量。
```
set ARM_SUBSCRIPTION_ID=your_subscription_id
set ARM_CLIENT_ID=your_appId
set ARM_CLIENT_SECRET=your_password
set ARM_TENANT_ID=your_tenant_id	
```

### 1.3 创建变量文件
在examples目录下创建 variables.tf 变量定义文件, 并声明变量和设置默认值。 

```
variable "prefix" {
  type = string
}

variable "location" {
  type    = string
  default = "eastasia"
}

variable "vm_usrname" {
  type    = string
  default = "vm-admin"
}

variable "vm_password" {
  type    = string
  default = "+123QWEasd"
}

variable "disk_size_gb" {
  type = number
}
```

在examples目录下创建 variable-dev.tfvars 变量文件,  并设置变量值。

```
prefix = "Dev"
disk_size_gb = 10
```


### 1.4 创建配置文件
 
在examples目录下创建 vm-deploy.tf 文件，在文件中声明Azure接口提供器和资源组。

```
provider "azurerm" {
  features {
    
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-TestResourceGroup"
  location = var.location
}
```

打开命令行工具并切换工作目录到examples目录下。

执行 'init' 初始化 terraform 模块。  
```
terraform init
```
执行 'plan' 命令检验执行计划, 该功能可以显示执行的细节。
```
terraform plan -var-file="variable-dev.tfvars"
```
执行 'apply' 命令, 创建资源组。
```
terraform apply -auto-approve -var-file="variable-dev.tfvars"
```

### 1.5 生成资源图表
执行 'graph' 命令生成 dot 数据, 并 执行 'dot' 命令 导出到 .svg 文件中。

```
terraform graph | dot -Tsvg > graph.svg
```


### 1.6 部署Azure虚拟机
+ 部署虚拟网络和子网 

在 vm-deploy.tf 文件中追加虚拟网络和子网声明。

```
resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-TestVnet"
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.prefix}-TestSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
```
执行 'apply' 命令, 创建虚拟网络和子网。

```
terraform apply -auto-approve -var-file="variable-dev.tfvars"
```

+ 部署公共IP地址

在 vm-deploy.tf 文件中追加公共IP地址声明。

```
resource "azurerm_public_ip" "pip" {
  name                = "${var.prefix}-TestPublicIP"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}
```

执行 'apply' 命令, 创建公共IP地址。

```
terraform apply -auto-approve -var-file="variable-dev.tfvars"
```

+ 部署网络安全组  

在 vm-deploy.tf 文件中追加网络安全组声明。

```
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-TestNetworkSecurityGroup"
  location            = var.location
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

执行 'apply' 命令, 创建网络安全组。

```
terraform apply -auto-approve -var-file="variable-dev.tfvars"
```

+ 部署网络接口控制器  

在 vm-deploy.tf 文件中追加网络接口声明。

```
resource "azurerm_network_interface" "nic" {
  name                = "${var.prefix}-TestNIC"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "${var.prefix}-TestNicConfiguration"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}
```

执行 'apply' 命令, 创建网络接口控制器。

```
terraform apply -auto-approve -var-file="variable-dev.tfvars"
```

+ 关联网络接口和网络安全组

在 vm-deploy.tf 文件中追加网络接口和网络安全组的关联声明。

```
resource "azurerm_network_interface_security_group_association" "if_nsg_assc" {
    network_interface_id      = azurerm_network_interface.nic.id
    network_security_group_id = azurerm_network_security_group.nsg.id
}
```

执行 'apply' 命令, 创建网络接口和网络安全组的关联。

```
terraform apply -auto-approve -var-file="variable-dev.tfvars"
```

+ 部署虚拟机
 
在 vm-deploy.tf 文件中追加虚拟机声明。

```
resource "azurerm_windows_virtual_machine" "winvm" {
  name                = "${var.prefix}-TestWinVM"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  size                = "Standard_F2"
  admin_username      = var.vm_usrname
  admin_password      = var.vm_password
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
执行 'apply' 命令, 创建虚拟机。

```
terraform apply -auto-approve -var-file="variable-dev.tfvars"
```


### 1.7 为虚拟机附加托管磁盘
+ 创建托管磁盘

在 vm-deploy.tf 文件中追加托管磁盘声明。

```
resource "azurerm_managed_disk" "disk" {
  name                 = "${azurerm_windows_virtual_machine.winvm.name}-disk1"
  location             = var.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = var.disk_size_gb
}
```

执行 'apply' 命令, 创建托管磁盘。

```
terraform apply -auto-approve -var-file="variable-dev.tfvars"
```

+ 虚拟机附加托管磁盘

在 vm-deploy.tf 文件中追加托管磁盘与虚拟机的关联声明。
```
resource "azurerm_virtual_machine_data_disk_attachment" "vm_disk_assc" {
  managed_disk_id    = azurerm_managed_disk.disk.id
  virtual_machine_id = azurerm_windows_virtual_machine.winvm.id
  lun                = "10"
  caching            = "ReadWrite"
}
```

执行 'apply' 命令, 创建托管磁盘与虚拟机的关联。

```
terraform apply -auto-approve -var-file="variable-dev.tfvars"
```

### 1.8 修改托管磁盘容量

在variable-dev.tfvars文件中, 属性 'disk_size_gb' 值修改为 15。
```
prefix = "Dev"
disk_size_gb = 15
```

执行 'apply' 命令,  修改托管磁盘容量。

```
terraform apply -auto-approve -var-file="variable-dev.tfvars"
```

### 1.9 分离与删除托管磁盘
+ 删除关联

从 vm-deploy.tf 文件中删除关联的声明。
```
resource "azurerm_virtual_machine_data_disk_attachment" "vm_disk_assc" {
  managed_disk_id    = azurerm_managed_disk.disk.id
  virtual_machine_id = azurerm_windows_virtual_machine.winvm.id
  lun                = "10"
  caching            = "ReadWrite"
}
```

执行 'apply' 命令, 删除托管磁盘和虚拟机直接的关联。

```
terraform apply -auto-approve -var-file="variable-dev.tfvars"
```


+ 删除托管磁盘  

将下面资源的声明从.tf文件中移除, 并执行 'apply' 命令。

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

执行 'apply' 命令, 删除托管磁盘。

```
terraform apply -auto-approve -var-file="variable-dev.tfvars"
```

### 1.10 销毁全部资源

执行 'destroy' 命令, 删除全部资源。

```
terraform destroy -var-file="variable-dev.tfvars"
```
### 第二部分 GitHub Actions实现Azure Terraform自动化部署
### 2.1 创建GitHub Secrets
将Azure Service Principle的凭据加入到版本库的Actions secrets。  
在GitHub Repo的机密库页面选择新建New Repository Secret功能并创建下面4个机密信息。
+ **ARM_CLIENT_ID**
+ **ARM_CLIENT_SECRET**
+ **ARM_SUBSCRIPTION_ID**
+ **ARM_TENANT_ID**

### 2.2 开发workflows yaml文件
+ 创建workflow文件目录  
在Terraform项目根目录创建.github/workflows目录。
+ 创建workflow文件  
在.github/workflows目录中创建azure_terraform_pipeline.yml文件, 文件内容如下。
```
name: Azure Terraform Pipeline
on:
  workflow_dispatch:
defaults:
  run:
    working-directory: examples
jobs:
  build:
    name: Build
    env:
      ARM_CLIENT_ID: ${{ secrets.ARM_CLIENT_ID }}
      ARM_CLIENT_SECRET: ${{ secrets.ARM_CLIENT_SECRET }}
      ARM_SUBSCRIPTION_ID: ${{ secrets.ARM_SUBSCRIPTION_ID }}
      ARM_TENANT_ID: ${{ secrets.ARM_TENANT_ID }}
      VAR_FILE: "variable-dev.tfvars"
    runs-on: ubuntu-latest
    steps:
    - name: Terraform checkout
      uses: actions/checkout@v2 

    - name: Terraform version
      run: terraform version
   
    - name: Terraform init
      run: terraform init
      
    - name: Terraform plan
      run: terraform plan -var-file="${{ env.VAR_FILE }}" -no-color

    - name: Terraform apply
      run: terraform apply -auto-approve -var-file="${{ env.VAR_FILE }}"    
```
> name  

workflow 的名称。

> on

指定触发 workflow 的条件。

> env

指定环境变量。

> jobs

要执行的一项或多项任务。

> runs-on

指定运行所需要的虚拟机环境。

> steps

指定每个 Job 的运行步骤, 可以包含一个或多个步骤。

> uses

要引用的action。

> run

step运行的命令。

### 2.3 运行workflows

在GitHub Repo的Actions页面选择要执行的workflow, 确认后开始执行。在workflow的运行列表中可以查看执行的详细情况, 每个Job和每个step的执行命令及参数。