# Script written by sziyan
# https://docs.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-powershell

#Import modules and setting environment
Import-Module Az.Accounts
Import-Module Az.Compute
Set-ExecutionPolicy -ExecutionPolicy Bypass
Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"

# Setting variables
$ResourceName = Read-Host -Prompt "Enter resource name to be creaated"
$Location = Read-Host -Prompt "Enter location for resource to be created at"
$username = Read-Host -Prompt "Enter username to be created as administrator"
echo "Use Get-AzVMImagePublisher,Get-AzVMImageOffer & Get-AzVMImageSku to obtain below details"
$PublisherName = Read-Host -Prompt "Enter publisher name of OS to be created in VM"
$Offer = Read-Host -Prompt "Enter offer of OS to be created in VM"
$Sku = Read-Host -Prompt "Enter SKU of OS to be created in VM"
echo "Publisher: $PublisherName, Offer: $Offer, SKU: $Sku"


# Creating new resource group
echo "Creating resource group $ResourceName at location $Location..."
New-AzResourceGroup -Name $ResourceName -Location $Location

# Create virtual network resources
echo "Creating virtual network resources..."
$subnetConfig = New-AzVirtualNetworkSubnetConfig -Name "mysubnet" -AddressPrefix 192.168.1.0/24
$vnet = New-AzVirtualNetwork -ResourceGroupName $ResourceName -Location $Location -Name "myVNET" -AddressPrefix 192.168.0.0/16 -Subnet $subnetConfig
$pip = New-AzPublicIpAddress -ResourceGroupName $ResourceName -Location $Location -AllocationMethod Static -IdleTimeoutInMinutes 4 -Name "mypublicdns$(Get-Random)"

# Security Group
echo "Creating security group..."

#port 22 
$nsgRuleSSH = New-AzNetworkSecurityRuleConfig `
  -Name "myNetworkSecurityGroupRuleSSH"  `
  -Protocol "Tcp" `
  -Direction "Inbound" `
  -Priority 1000 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 22 `
  -Access "Allow"

  #port 80
  $nsgRuleWeb = New-AzNetworkSecurityRuleConfig `
  -Name "myNetworkSecurityGroupRuleWWW"  `
  -Protocol "Tcp" `
  -Direction "Inbound" `
  -Priority 1001 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 80 `
  -Access "Allow"

  # Create a network security group
$nsg = New-AzNetworkSecurityGroup `
  -ResourceGroupName $ResourceName `
  -Location $Location `
  -Name "myNetworkSecurityGroup" `
  -SecurityRules $nsgRuleSSH,$nsgRuleWeb

# Create a virtual network card and associate with public IP address and NSG
$nic = New-AzNetworkInterface `
  -Name "myNic" `
  -ResourceGroupName $ResourceName `
  -Location $Location `
  -SubnetId $vnet.Subnets[0].Id `
  -PublicIpAddressId $pip.Id `
  -NetworkSecurityGroupId $nsg.Id

# Configuration of VM

# Define a credential object
$securePassword = ConvertTo-SecureString ' ' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($username, $securePassword)

# Create a virtual machine configuration
echo "Creating virtual machine configuration..."

$vmConfig = New-AzVMConfig `
  -VMName "myVM" `
  -VMSize "Standard_D1" | `
Set-AzVMOperatingSystem `
  -Linux `
  -ComputerName "myVM" `
  -Credential $cred `
  -DisablePasswordAuthentication | `
Set-AzVMSourceImage `
  -PublisherName $PublisherName `
  -Offer $Offer `
  -Skus $Sku `
  -Version "latest" | `
Add-AzVMNetworkInterface `
  -Id $nic.Id

# Configure the SSH key
$sshPublicKey = cat ~/.ssh/id_rsa.pub
$path = "/home/" + $username + "/.ssh/authorized_keys"
Add-AzVMSshPublicKey `
  -VM $vmconfig `
  -KeyData $sshPublicKey `
  -Path $path

# Creation of VM
echo "Creating virtual machine..."
New-AzVM `
  -ResourceGroupName $ResourceName `
  -Location $Location -VM $vmConfig

# Get ip address
$ip_address = Get-AzPublicIpAddress -ResourceGroupName $ResourceName | Select "IpAddress"
echo $ip_address
pause