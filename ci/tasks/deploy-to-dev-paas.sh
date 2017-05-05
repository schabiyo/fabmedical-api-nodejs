#!/bin/bash

set -e -x


echo "Deploying to DEV PAAS"

echo "Image version: "
#cat api-version/number

#touch tag-out/rc_tag
#echo "1.0.1" >> tag-out/rc_tag
## Config the Docker Container
# 1-Login to Azure using the az command line

az login --service-principal -u "$service_principal_id" -p "$service_principal_secret" --tenant "$tenant_id"
az account set --subscription "$subscription_id"
az appservice web config container update -n $server_prefix-api-nodejs -g $paas_rg \
    --docker-registry-server-password $acr_password \
    --docker-registry-server-user $acr_username \
    --docker-registry-server-url $acr_endpoint \
    --docker-custom-image-name $acr_endpoint/ossdemo/api-nodejs

