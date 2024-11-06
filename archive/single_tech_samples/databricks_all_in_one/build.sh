#!/usr/bin/env bash

unset username
unset password

read -p 'Client PC Username: ' username
while true; do
  read -s -p "Client PC Password: " password
  echo
  read -s -p "Client PC Password (again): " password2
  echo
  [ "$password" = "$password2" ] && break
  echo "Please try again"
done
echo "Ok"

echo "Running Bicep Main deployment file"
bicep_output=$(az deployment sub create \
    --location "southeastasia" \
    --template-file main.bicep \
    --parameters adminUsername=$username \
    --parameters adminPassword=$password \
    --parameters linkAkstoAml=true \
    --parameters deployADBCluster=true \
    --parameters updateAKVKeys=true \
    --only-show-errors)

if [[ -z "$bicep_output" ]]; then
    echo "Deployment failed, check errors on Azure portal"
    exit 1
fi

echo "$bicep_output" >output.json # save output
echo "Bicep deployment. Done"
