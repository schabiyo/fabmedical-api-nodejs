#!/bin/bash

set -e -x

echo "Deploying to STAGING K8s"
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
echo "create secret to login to the private registry"

sed -i -e "s@API-NODEJS-REPOSITORY@${api_repository}@g" api-nodejs/ci/tasks/k8s/api-deploy-staging.yml

#Delete current deployment first
check=$(~/kubectl get deployment -l app=api-nodejs,env=staging)
if [[ $check != *"NotFound"* ]]; then
  echo "Deleting existent deployment"
  ~/kubectl delete deployment -l app=api-nodejs,env=staging
  ~/kubectl delete svc -l app=api-nodejs,env=staging
fi

~/kubectl create -f api-nodejs/ci/tasks/k8s/api-deploy-staging.yml
echo "Initial deployment & expose the service"
~/kubectl expose deployments --port=80 --target-port=3001 --type=LoadBalancer -l app=api-nodejs,env=staging

externalIP="pending"
while [[ $externalIP == *"endin"*  ]]; do
  echo "Waiting for the service to get exposed..."
  sleep 30s
  line=$(~/kubectl get services | grep 'api-nodejs')
  IFS=' '
  read -r -a array <<< "$line"
  externalIP="${array[2]}"
done

echo "The API Service is exposed on :$externalIP "