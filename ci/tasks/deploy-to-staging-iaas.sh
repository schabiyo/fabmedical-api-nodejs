#!/bin/bash

set -e -x

echo "Deploying to STAGING IAAS"
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
chmod 600 ~/.ssh/id_rsa*

api_repository=$acr_endpoint/ossdemo/api-nodejs:$img_tag

touch api-nodejs/ci/tasks/ansible/docker-hosts
printf "%s\n" "[dockerhosts]" >> api-nodejs/ci/tasks/ansible/docker-hosts
printf "%s\n" "staging-${server_prefix}.${server_location}.cloudapp.azure.com" >> api-nodejs/ci/tasks/ansible/docker-hosts
#printf "%s\n" "staging-${server_prefix}.${server_location}.cloudapp.azure.com" >> api-nodejs/ci/tasks/ansible/docker-hosts

sed -i -e "s@VALUEOF-DEMO-ADMIN-USER-NAME@${server_admin_username}@g" api-nodejs/ci/tasks/ansible/playbook-iaas-docker-deploy.yml
sed -i -e "s@VALUEOF-REGISTRY-SERVER-NAME@${acr_endpoint}@g" api-nodejs/ci/tasks/ansible/playbook-iaas-docker-deploy.yml
sed -i -e "s@VALUEOF-REGISTRY-USER-NAME@${acr_username}@g" api-nodejs/ci/tasks/ansible/playbook-iaas-docker-deploy.yml
sed -i -e "s@VALUEOF-REGISTRY-PASSWORD@${acr_password}@g" api-nodejs/ci/tasks/ansible/playbook-iaas-docker-deploy.yml
sed -i -e "s@VALUEOF-IMAGE-REPOSITORY@${api_repository}@g" api-nodejs/ci/tasks/ansible/playbook-iaas-docker-deploy.yml

cd api-nodejs/ci/tasks/ansible
 ansible-playbook -i docker-hosts playbook-iaas-docker-deploy.yml --private-key ~/.ssh/id_rsa
cd ..

echo -e ".you can now browse the application at http://staging-${server_prefix}.${server_location}.cloudapp.azure.com for individual servers."

