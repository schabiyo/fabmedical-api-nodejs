#!/bin/bash

set -e -x


echo "Deploying to DEV PAAS"

echo "Image version: "
#cat api-version/number

#touch tag-out/rc_tag
#echo "1.0.1" >> tag-out/rc_tag
## Config the Docker Container
az appservice web config container update -n $server_prefix-api-nodejs -g ossdemo-paas \
    --docker-registry-server-password $acr_password \
    --docker-registry-server-user $acr_username \
    --docker-registry-server-url $acr_endpoint \
    --docker-custom-image-name $acr_endpoint/ossdemo/api-nodejs

