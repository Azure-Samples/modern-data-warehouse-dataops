# Parking Sensor Data Generator

## Run data simulator locally (with devcontainer)

- Navigate to `application` directory
- execute `npm install` to install dependencies
- execute `npm audit fix` if any dependencies indicated vulnerabilities
- execute `node app.js` to start the express server
- use a browser to connect to `http://localhost:3000/sensors` or `http://localhost:3000/locations` to examine data.
- use `ctrl+c` to exit the express server

## Bicep Deployment

- navigate to the `bicep` folder
- Execute `az login` and select your subscription if prompted
- execute `./deploy.sh <location>` from a bash shell (i.e. `./deploy.sh eastus2`)

## Terraform Deployment (do not run in devcontainer because it's not set up for Docker-in-Docker)

- Execute `az login` and select your subscription if prompted
- Navigate to the `terraform\rest` folder
- update the `providers.tf` file with your Azure Subscription Id
- update the `variables.tf` with location and any changes to naming
- execute `terraform init` to install dependent modules
- execute `terraform plan`
- verify planned outputs
- execute `terraform apply`
- execute `terraform output` to get the IP Address of the running container
- verify deployment by navigating to `https://<ipaddress>/sensors` or `https://<ipaddress>/locations`
