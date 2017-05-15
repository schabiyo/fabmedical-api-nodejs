#!/bin/bash

echo "Deploying to PROD K8s"
img_tag=$(<api-version/number)
echo "Image version: "$img_tag

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

sed -i -e "s@WEB-NODEJS-REPOSITORY@${api_repository}@g" api-nodejs/ci/tasks/k8s/api-deploy.yml

set +e
#Delete current deployment first
check=$(~/kubectl get deployment api-nodejs --namespace ossdemo-prod)
if [[ $check != *"NotFound"* ]]; then
  echo "Deleting existent deployment"
  result=$(eval ~/kubectl delete deployment api-nodejs --namespace ossdemo-prod)
  echo result 
fi

check=$(~/kubectl get svc api-nodejs --namespace ossdemo-prod)
if [[ $check != *"NotFound"* ]]; then
  echo "Deleting existent  service"
  result=$(eval ~/kubectl delete svc api-nodejs --namespace ossdemo-prod)
  echo result
fi

set -e

~/kubectl create -f api-nodejs/ci/tasks/k8s/api-deploy.yml --namespace=ossdemo-prod
echo "Initial deployment & expose the service"
~/kubectl expose deployments api-nodejs --port=80 --target-port=3000 --type=LoadBalancer --name=api-nodejs --namespace=ossdemo-prod

externalIP="pending"
while [[ $externalIP == *"endin"*  ]]; do
  echo "Waiting for the service to get exposed..."
  sleep 30s
  line=$(~/kubectl get services --namespace ossdemo-prod | grep 'api-nodejs')
  IFS=' '
  read -r -a array <<< "$line"
  externalIP="${array[2]}"
done

echo "The WEB app is exposed on :$externalIP "
