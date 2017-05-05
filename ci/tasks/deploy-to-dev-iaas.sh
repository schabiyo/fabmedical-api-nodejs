#!/bin/bash

set -e -x

echo "Deploying to DEV PAAS"
img_tag=$(<api-version/number)
echo "Image version: "$img_tag

echo -e "Deploy containers via ansible to worker iaas servers..."
#change into the directory where the Ansible CFG is located

mkdir ~/.ssh
#Had to do this as the key is being read in one single line
printf "%s\n" "-----BEGIN RSA PRIVATE KEY-----" >> ~/.ssh/id_rsa
printf "%s\n" $server_ssh_private_key | tail -n +5 | head -n -4 >>  ~/.ssh/id_rsa
printf "%s" "-----END RSA PRIVATE KEY-----" >> ~/.ssh/id_rsa

echo $server_ssh_public_key >> ~/.ssh/id_rsa.pub

api_repository=$acr_endpoint/ossdemo/api-nodejs:$img_tag

touch api-nodejs/ansible/docker-hosts
printf "%s\n" "[dockerhosts]" >> api-nodejs/ansible/docker-hosts
printf "%s\n" "web1-${server_prefix}.${server_location}.cloudapp.azure.com" >> api-nodejs/ansible/docker-hosts
printf "%s\n" "web2-${server_prefix}.${server_location}.cloudapp.azure.com" >> api-nodejs/ansible/docker-hosts

sed -i -e "s@VALUEOF-DEMO-ADMIN-USER-NAME@${server_admin_username}@g" api-nodejs/ansible/playbook-iaas-docker-deploy.yml
sed -i -e "s@VALUEOF-REGISTRY-SERVER-NAME@${acr_endpoint}@g" api-nodejs/ansible/playbook-iaas-docker-deploy.yml
sed -i -e "s@VALUEOF-REGISTRY-USER-NAME@${acr_username}@g" api-nodejs/ansible/playbook-iaas-docker-deploy.yml
sed -i -e "s@VALUEOF-REGISTRY-PASSWORD@${acr_password}@g" api-nodejs/ansible/playbook-iaas-docker-deploy.yml
sed -i -e "s@VALUEOF-IMAGE-REPOSITORY@${api_repository}@g" api-nodejs/ansible/playbook-iaas-docker-deploy.yml

cd ansible
 ansible-playbook -i docker-hosts ansible-iaas-docker-deploy.yml
cd ..

echo ""
echo -e "${BOLD}Browse application...${RESET}"
echo -e ".you can now browse the application at http://svr1-VALUEOF-UNIQUE-SERVER-PREFIX.eastus.cloudapp.azure.com for individual servers."
echo -e ". or at http://VALUEOF-UNIQUE-SERVER-PREFIX-iaas-demo.eastus.cloudapp.azure.com for a loadbalanced IP."


az login --service-principal -u "$service_principal_id" -p "$service_principal_secret" --tenant "$tenant_id"
az account set --subscription "$subscription_id"
az appservice web config container update -s dev -n $server_prefix-api-nodejs -g $paas_rg \
    --docker-registry-server-password $acr_password \
    --docker-registry-server-user $acr_username \
    --docker-registry-server-url $acr_endpoint \
    --docker-custom-image-name $acr_endpoint/ossdemo/api-nodejs:$img_tag

