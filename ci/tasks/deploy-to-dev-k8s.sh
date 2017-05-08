#!/bin/bash

set -e -x

echo "Deploying to DEV K8s"
img_tag=$(<api-version/number)
echo "Image version: "$img_tag

#touch tag-out/rc_tag
#echo "1.0.1" >> tag-out/rc_tag
## Config the Docker Container
# 1-Login to Azure using the az command line

az login --service-principal -u "$service_principal_id" -p "$service_principal_secret" --tenant "$tenant_id"
az account set --subscription "$subscription_id"

az acs kubernetes install-cli --install-location ~/kubectl

mkdir ~/.ssh
#Had to do this as the key is being read in one single line
printf "%s\n" "-----BEGIN RSA PRIVATE KEY-----" >> ~/.ssh/id_rsa
printf "%s\n" $server_ssh_private_key | tail -n +5 | head -n -4 >>  ~/.ssh/id_rsa
printf "%s" "-----END RSA PRIVATE KEY-----" >> ~/.ssh/id_rsa
echo $server_ssh_public_key >> ~/.ssh/id_rsa.pub
chmod 600 ~/.ssh/id_rsa*

api_repository=$acr_endpoint/ossdemo/api-nodejs:$img_tag

az acs kubernetes get-credentials --resource-group=$acs_rg --name k8s-$server_prefix

~/kubectl run api-nodejs --image $acr_endpoint/ossdemo/api-nodejs:$img_tag

~/kubectl expose deployments api-nodejs --port=80 --target-port=3001 --type=LoadBalancer

#Wait unitl we get an external IP
~/kubectl get svc
