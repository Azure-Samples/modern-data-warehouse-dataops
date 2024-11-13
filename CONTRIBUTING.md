# Contributing <!-- omit in toc -->

Thank you for your interest in contributing! 👍🏼

The following is a set of guidelines to contributing to the DataOps repo.

## Table of Contents <!-- omit in toc -->

- [Code of Conduct](#code-of-conduct)
- [What should I know before I get started?](#what-should-i-know-before-i-get-started)
- [Creating a new sample](#creating-a-new-sample)
  - [Pre-requisites](#pre-requisites)
  - [Repo Structure](#repo-structure)
  - [Getting Started](#getting-started)
    - [Sample's README.md file](#samples-readmemd-file)
    - [Automated Deployment](#automated-deployment)
- [Contributing to an existing sample](#contributing-to-an-existing-sample)
- [Labels](#labels)
- [Branching structure](#branching-structure)
- [Contributor License Agreement (CLA)](#contributor-license-agreement-cla)

## Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/).
For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or
contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## What should I know before I get started?

The DataOps repo is a collection of end-to-end samples, smaller single-technology samples, and utility code snippets, which aim to help data engineers operationalize their data systems using DevOps principles with Microsoft technologies. Each sample showcases one or more of the following engineering fundamental pillars: **Infrastructure-as-code (IaC)**, **CI/CD**, **automated testing**, and **observability** but may also cover additional principals as detailed in the [Microsoft Azure Well-Architected Framework](https://docs.microsoft.com/en-us/azure/architecture/framework/).

## Creating a new sample

### Pre-requisites

1. Review existing samples to ensure you are not duplicating work. Additionally, check [Github issues](https://github.com/Azure-Samples/modern-data-warehouse-dataops/issues) for any similar work in progress (i.e., issues with associated PRs).

2. Once you've confirmed this, you need to decide whether you are creating either an end-to-end sample or a single-technology sample:

    - [End-to-end samples](/e2e_samples/) - Reference-architecture style DataOps samples typically utilizing a number of Microsoft services and technologies.
       - **Purpose**: Showcase a number of DataOps key concepts in a concrete, end-to-end data sample.

    - [Single-technology samples](/single_tech_samples/) - Smaller, modular samples focusing on a single Azure service showcasing one or two key DataOps concepts.
       - **Purpose**: Allows developers and data engineers to easily choose and reuse individual samples based on their requirements, without the complexity of an end-to-end sample. The small and modular design also allows for showcasing different implementations for the same concept.

    - [Utilities](/utilities/) - Reusable, standalone scripts that help with a specific operational task.
       - **Purpose**: Easily find helpful scripts used in common tasks to manage a data engineering system.

3. Decide which [key concepts](https://docs.microsoft.com/en-us/azure/architecture/framework/) are you showcasing in your sample. See [Microsoft Azure Well-Architected Framework](https://docs.microsoft.com/en-us/azure/architecture/framework/) for additional information. If you've decided to build a single-technology sample, decide which technology will be showcasing the key concepts.

4. Determine the appropriate location for your sample within the [repository structure](#repo-structure). Select a short, descriptive name for the sample, avoiding lengthy or complex names, as it will be used throughout the repo (e.g., folder names, script paths, documentation links, and labels).

5. Create a github issue using the [new sample setup](./.github/ISSUE_TEMPLATE/new-sample-setup.md) template and fill in the information required. This template includes a detailed checklist to guide you through the sample development process.

### Repo Structure

```text
/e2e_samples
  /<name-of-e2e-sample-1>
/single_tech_samples
  /azuresql
  /cosmosdb
  /fabric
  /databricks
    /<name-of-singletech-sample-1>
    /<name-of-singletech-sample-2>
  ...
/utilities
  /fabric
    /<name-of-utility-1>
    /<name-of-utility-2>
  /databricks
```

### Getting Started

Once you have done all of the above, refer to this [sample structure](/docs/sample_project_structure/README.md) to get started and use it as the starting point.

#### Sample's README.md file

This is arguably the *most important* part of your sample. It is recommended to consolidate most content in a single README to prevent information from being 'lost' or overlooked through through deep linking. Below is a brief description of the different sections in this file:

1. **Table of Contents** - Use [this VSCode extension](https://marketplace.visualstudio.com/items?itemName=yzhang.markdown-all-in-one) to generate the Table of Contents (TOC).
1. **Solution Overview** - Provide the background of the solution (i.e., What problem are you trying to solve?), solution architecture and key technologies used.
1. **Key Learnings** - These are the key takeaways you want to impart to the engineer trying out the sample. For example, "Make your data pipelines replayable and idempotent".
1. **Key Concepts** - These are the DataOps and WAF concepts that the sample is showcasing. For example, "Continuous Integration". This will form the core of your sample.
1. **How to use the sample** - Clear deployment instructions, including all pre-requisites and a a list of deployed resources.
1. **Known Issues, Limitations and Workarounds** - Elaborate on any issues and deficiency in the provided solution that the reader should be aware of. Highlight any key WAF concepts that the solution **does not address** and any workarounds present in the deployment script.

#### Automated Deployment

> NOTE: This requirement is not yet consistently enforced but will eventually be required to facilitate automated testing of all deployment scripts of all samples.

Ensure you have a `deploy.sh` or `deploy.ps1` in the root of the sample as the entry point of the deployment of your sample.

## Contributing to an existing sample

1. Look through Github issues if there are any similar work in progress (i.e., issues with PRs associated to them) to avoid duplicate efforts.

2. Create a Github issue detailing your work using the [Feature](.github/ISSUE_TEMPLATE/feature.md) issue template. Tag the issue using the relevant label (i.e., 'single-tech: databricks', 'e2e: fabric'). See [Labels](#labels) below.

3. Develop your changes. If you are not a member of the [Azure-Samples](https://github.com/Azure-Samples) organization (Microsoft employees only), you will need to fork the repository. Otherwise, familiarize yourself with the [branching structure](#branching-structure). Every sample should include developer setup information, and most should provide a Devcontainer.

4. Raise a PR and fill up the PR template including associating it to the correct Github issue. Ensure you apply the correct label to the PR. This repo has a number of automated checks such as linting, link checks, and more. See [.github/workflows](/.github/workflows/) folder for details.

## Labels

Ensure you are applying the appropriate labels to issues.

Minimum **required** labels is either `e2e: <sample_name>` or `single-tech: <technology>`. **It is important that the correct label is applied to ensure the issue is routed to the appropriate team backlog.**

It is also encouraged (not required) to label work related to key concepts. i.e., `key-concept: load testing`.

View [existing labels](https://github.com/Azure-Samples/modern-data-warehouse-dataops/labels?sort=name-asc) for more information.

## Branching structure

Create a designated **feature branch** for the sample you will be building: `feat/<name-sample>`.

For individual developer branches, use: `developer_name/branch`.

Developers can also choose to fork the repo and work off that. Make sure to submit your PR to the Feature Branch first before raising a PR to the `main` branch.

Please delete the source branches after merging the content. Stale branches (no commits in last 120 days) may be deleted without prior notice.

## Contributor License Agreement (CLA)

Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit [https://cla.opensource.microsoft.com](https://cla.opensource.microsoft.com).

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.
