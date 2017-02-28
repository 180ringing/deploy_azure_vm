#!/bin/bash
set -e

# Create VM in MS Azure
# Inspired by
# https://docs.microsoft.com/en-us/azure/virtual-machines/virtual-machines-linux-create-cli-complete-nodejs?toc=%2fazure%2fvirtual-machines%2flinux%2ftoc.json

# Secrets
# Put here or export before script run
# https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-create-service-principal-portal
AZURE_CLIENT_ID=""
AZURE_SECRET=""
AZURE_SUBSCRIPTION_ID=""
AZURE_TENANT=""

# Vars
NAME='qctest8'  ### <-- Change Me
DNS_PREFIX='prfx'
VNET_PREFIX='10.2.0.0'
DEFAULT_USER='azure'
VM_SIZE="Standard_DS2_v2"

# Don't forget to install azure-cli 
# https://docs.microsoft.com/en-us/azure/xplat-cli-install

azure login -u ${AZURE_CLIENT_ID} --service-principal --tenant ${AZURE_TENANT} -p ${AZURE_SECRET}
azure config mode arm
azure group create --name ${NAME} --location westeurope
azure storage account create -g ${NAME} -l westeurope  --type PLRS ${NAME}storage
azure network vnet create -g ${NAME} -l westeurope -n myVnet -a ${VNET_PREFIX}/16
azure network vnet subnet create -g ${NAME} -e myVnet -n mySubnet -a ${VNET_PREFIX}/24
azure network public-ip create -g ${NAME} -l westeurope -n myPublicIP  -d ${DNS_PREFIX}-${NAME} -a static -i 30

#azure network nsg create -g ${NAME} -l westeurope -n myNetworkSecurityGroup
azure network nic create -g ${NAME} -l westeurope -n myNic1 -m myVnet -k mySubnet --public-ip-name myPublicIP
azure availset create -g ${NAME} -l westeurope -n myAvailabilitySet
azure vm create --resource-group ${NAME} --name ${NAME}-1 --location westeurope --os-type linux --availset-name myAvailabilitySet --nic-name myNic1  --vnet-name myVnet  --vnet-subnet-name mySubnet --storage-account-name ${NAME}storage  --image-urn canonical:UbuntuServer:16.04-LTS:latest  --ssh-publickey-file ~/.ssh/id_rsa.pub --admin-username ${DEFAULT_USER} --vm-size ${VM_SIZE}

MYIP=$(azure network public-ip show ${NAME} myPublicIP | grep 'IP Address' | awk '{print $5}')

echo 
echo
echo "  DONE!"
echo "  Now you can login to your vm:"
echo "ssh ${DEFAULT_USER}@${MYIP}"
echo "  or:"
echo "ssh ${DEFAULT_USER}@${DNS_PREFIX}-${NAME}.westeurope.cloudapp.azure.com"

# And some cool stuff

#azure vm show -g qctest7 -n qctest7-1
#azure vm disk attach-new -g qctest7 -n qctest7-1 --vhd-name qctest7-1-datadisk-1 --storage-account-name qctest7storage --size-in-gb 1023 --host-caching ReadOnly

#azure vm image list-skus westeurope
#azure vm image list-publishers westeurope
#azure vm image list-offers westeurope Canonical
#azure vm image list-skus westeurope Canonical UbuntuServer
#azure vm image list  westeurope Canonical UbuntuServer 16.04-LTS
#azure vm sizes --location westeurope
