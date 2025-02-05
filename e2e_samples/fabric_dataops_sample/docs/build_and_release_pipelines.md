# Build and release pipelines <!-- omit in toc -->

## Contents <!-- omit in toc -->

- [CI pipelines](#ci-pipelines)
  - [QA pipeline](#qa-pipeline)
  - [QA cleanup pipeline](#qa-cleanup-pipeline)
  - [Build artifacts pipeline](#build-artifacts-pipeline)
- [CD pipelines](#cd-pipelines)
  - [Release deploy pipeline](#release-deploy-pipeline)

## CI pipelines

### QA pipeline

The 'QA pipeline' is triggered whenever a pull request (PR) is submitted to the `dev` branch. This pipeline tests the functionality and checks for conflicts before merging the feature into the main branch. It includes the following steps:

- Runs Python unit tests to validate the functionality of libraries used in the solution.
- Runs Fabric unit tests to ensure the stability of the Fabric workspace. This involves automating the creation of an ephemeral workspace. The steps include:
  - Creating a new ephemeral workspace.
  - Syncing the `feature` branch to the ephemeral workspace to create the Fabric items.
  - Setting up configurations not covered by Git syncing.
  - Running tests in the ephemeral workspace created.

Refer to [devops/templates/pipelines/azure-pipelines-ci-qa.yml](./../devops/templates/pipelines/azure-pipelines-ci-qa.yml) for the actual pipeline definition.

### QA cleanup pipeline

As mentioned above, the 'QA pipeline' creates a new ephemeral Fabric workspace for each PR. Once this PR is closed or abandoned, the 'QA cleanup pipeline' ensures that these temporary resources are deleted, freeing up system resources.

Refer to [devops/azure-pipelines-ci-qa-cleanup.yml](./../devops/azure-pipelines-ci-qa-cleanup.yml) for the actual pipeline definition.

### Build artifacts pipeline

The 'Build artifacts pipeline' is triggered once the feature PR is merged to the `dev` branch. This pipeline publishes configuration files and custom libraries as artifacts, which are then used by the release and deployment pipeline.

Refer to [/devops/templates/pipelines/azure-pipelines-ci-artifacts.yml](./../devops/templates/pipelines/azure-pipelines-ci-artifacts.yml) for the actual pipeline definition.

## CD pipelines

### Release deploy pipeline

The 'Release deploy pipeline' is triggered when the CI 'Build artifacts pipeline' completes successfully. This pipeline deploys the published artifacts to different environments (dev, stg, prod etc.). Manual approval is required before proceeding to the next stage, ensuring controlled deployment.
