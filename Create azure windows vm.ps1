# Script written by sziyan
# https://docs.microsoft.com/en-us/azure/virtual-machines/windows/quick-create-powershell

# Import modules and setting environment
Set-ExecutionPolicy -ExecutionPolicy Bypass
Import-Module Az.Compute
Import-Module Az.Accounts

# Logging in to Microsoft Account
echo "Login to Microsoft AD account with rights to create VM"
Login-AzAccount
echo "Login successful!"

# Setting variable
echo "Obtaining information for creation of VM"
$ResourceName = Read-Host -Prompt 'Enter resource name to create'
$VMName = Read-Host -Prompt "Enter VM name"
$Location = Read-Host -Prompt "Enter location to create resource in"
$Username = Read-Host -Prompt "Enter username to be created as admin"
$Password = Read-Host "Enter password to be created for admin" -AsSecureString
echo "Creating Windows Server VM with default settings.."

#Creating VM
echo "Creating virtual machine..."
$cred = New-Object System.Management.Automation.PSCredential ($Username, $Password)
New-AzVm -ResourceGroupName $ResourceName -Name $VMName -Location $Location -VirtualNetworkName "myVNET" `
-SubnetName "mysubnet" -SecurityGroupName "myNetworkSecurity" -PublicIpAddressName "mypublicip" -OpenPorts 80,3389 -Credential $cred

# Get ip address
$ip_address = Get-AzPublicIpAddress -ResourceGroupName $ResourceName | Select "IpAddress"
echo $ip_address
pause
