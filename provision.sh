#!/bin/bash

rg_name=rg5
token=ARW2HXZWPJ2D67DZP57I4C3GABHBE

az group create --location swedencentral --name $rg_name
az deployment group create --resource-group $rg_name --template-file arm.json \
    --parameters AdminUser=azureuser sshRSAPublicKey="$(cat ~/.ssh/id_rsa.pub)" customDataAppServer=@cloudinitdotnet.sh customDataRevProxies=@cloudinitrevproxy.sh 
public_ip=$(az vm show --resource-group $rg_name --name vmbastion --show-details --query [publicIps] --output tsv)

eval $(ssh-agent)

ssh-add ~/.ssh/id_rsa

ssh -o StrictHostKeyChecking=no -A -N -L 2222:10.0.0.10:22 azureuser@$public_ip &

ssh -o StrictHostKeyChecking=no -p 2222 azureuser@localhost "mkdir actions-runner && cd actions-runner && \
    curl -o actions-runner-linux-x64-2.314.1.tar.gz \
    -L https://github.com/actions/runner/releases/download/v2.314.1/actions-runner-linux-x64-2.314.1.tar.gz && \
    echo \"6c726a118bbe02cd32e222f890e1e476567bf299353a96886ba75b423c1137b5  actions-runner-linux-x64-2.314.1.tar.gz\" | \
    shasum -a 256 -c && tar xzf ./actions-runner-linux-x64-2.314.1.tar.gz &&  \
    ./config.sh --unattended --url https://github.com/mina-mtb/CloToDo --token $token && sudo ./svc.sh install azureuser && sudo ./svc.sh start"
