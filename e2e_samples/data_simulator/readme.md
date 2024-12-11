# Parking Sensor Data Simulator

This documentation will be fleshed out...just want to have something usable by the team to unblock development.

## Introduction

    Batch
    Streaming
    REST

## Configuration Options

    Since this is focused on REST...this is the .env configuration you should have to replicate our previous functionality

    ```
    SENSORFILE="./collections/sensors.json"
    OUTPUTFILEPREFIX="parking"
    DEFAULTDATACLASS="kerbsidesensor"
    WRITETEMPLATE=true
    ```

## Requirements

Azure Subscription
Nodejs
Docker
Terraform

## Running Locally

Change to "application" folder
Set .env variables
Run `npm install`
Run `node ./app.js`
REST API will be [http://localhost:3000](http://localhost:3000)

## Running in the Cloud

Change to "terraform" folder
login to Azure with 'az login'
verify subscription with 'az account show'
run `terraform plan`
verify outputs
run `terraform apply`

REST API should be accessible at the http address of the Terraform output.

Cleanup:
run `terraform destroy`
