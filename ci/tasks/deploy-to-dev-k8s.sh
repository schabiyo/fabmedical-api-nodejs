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

az acs kubernetes get-credentials --resource-group=$acs_rg --name k8s-$server_prefix

kubectl run api-nodejs --image $acr_endpoint/ossdemo/api-nodejs:$img_tag

kubectl expose deployments nginx --port=80 --type=LoadBalancer

#Wait unitl we get an external IP
kubectl get svc
