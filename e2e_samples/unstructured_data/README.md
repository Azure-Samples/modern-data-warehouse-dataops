# Unstructured Data Processing  <!-- omit in toc -->

This is a reference implementation of an end to end data pipeline for processing unstructured data. The high level goal of this implementation is to:

- Ingest unstructured data as pdf documents
- Use Azure AI Services to extract and evaluate text data
- Enable human in the look feedback with a the citation tool
- Serve the data for a RAG application

As a reference implementation, this should serve as an experiment to deploy in a sandbox or dev environment to explore capabilities.

## Contents <!-- omit in toc -->

- [Architecture](#architecture)
- [How to use the sample](#how-to-use-the-sample)
- [Cleaning up](#cleaning-up)

## Architecture

![Application Architecture](images/application_architecture.drawio.png)

## How to use the sample

```bash
cd e2e_samples/unstructured_data

cp .envtemplate .env

# stop
# fill in .env with your required variables
# then
chmod +x ./deploy.sh

./deploy.sh
```

## Cleaning up

TODO: Destroy steps
