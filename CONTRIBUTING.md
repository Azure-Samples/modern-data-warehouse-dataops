# Contributing <!-- omit in toc -->

Thank you for your interest in contributing! 👍🏼

The following is a set of guidelines to contributing to the DataOps repo.

## Table of Contents <!-- omit in toc -->

- [Code of Conduct](#code-of-conduct)
- [What should I know before I get started?](#what-should-i-know-before-i-get-started)
- [Creating a new sample](#creating-a-new-sample)
  - [Pre-requisites](#pre-requisites)
  - [Getting Started](#getting-started)
    - [Your sample's README](#your-samples-readme)
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

The DataOps repo is a collection of end-to-end samples, smaller single technology samples, and utility code snippets which aims help data engineers operationalize their data systems using DevOps principals with Microsoft technologies. Each sample showcases one or more of the following engineering fundamental pillars: **Infrastructure-as-code (IaC)**, **CI/CD**, **automated testing**, and **observability** but may also cover additional principals as covered by the [Microsoft Azure Well-Architected Framework](https://docs.microsoft.com/en-us/azure/architecture/framework/).

## Creating a new sample

### Pre-requisites

**First**, look through existing samples to ensure you are not duplicating work. Also, look through Github issues if there is any similar work in progress (ie. issues with PRs associated to them).

**Second**, once you've confirmed this, you need to decide whether you are creating either an End-to-End Sample or a Single Technology Sample.

1. [End-to-End Samples](/e2e_samples/) - Reference-architecture style DataOps samples typically utilizing a number of Microsoft services and technologies.
   - **Purpose**: Showcase a number of DataOps key concepts in a concrete, end-to-end data pipeline.

2. [Single Technology Samples](/single_tech_samples/) - Smaller, modular samples focusing on a single Azure service showcasing one or two DataOps key concepts.
   - **Purpose**: allows Developers and Data Engineers to easily choose and reuse individual samples depending on their requirements without the complexity of an end-to-end sample. Being small and modular also allows for showcasing different implementations for the same concept.

3. [Utilities](/utilities/) - Reusable, standalone scripts that help with a specific operational task.
   - **Purpose**: Easily find helpful scripts used in common tasks to manage a data engineering system.

**Third**, decide which [key concepts](https://docs.microsoft.com/en-us/azure/architecture/framework/) are you showcasing in your sample. See [Microsoft Azure Well-Architected Framework](https://docs.microsoft.com/en-us/azure/architecture/framework/) for additional information. If you've decided to build a Single Technology Sample, decide which technology will be showcasing the key concepts.

**Fourth**, locate where in the repository structure your sample will sit. Decide on the name of the sample -- short descriptive names are best. It is recommended to **not** choose a name too lengthy and complicated as it will be used across the repo (folder name, script paths, deep-linking in docs, labels, etc.).

Repo Structure:

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

**Fifth**, Create a Github issue using the "New Sample Setup" template and fill in the information required. This issue template also contains a detailed checklist to guide you in your sample development.

### Getting Started

Once you have done all of the above, see this [sample structure](/docs/sample_project_structure/README.md) to get started. Use that structure as a starting point.

#### Your sample's README

This is arguably the *most important* part of your sample. In general, it is recommended to put most of the content in a single README to avoid content being "lost" and skipped over through deep linking.

Structure of the README:

1. **Table of Contents** - Use [this VSCode extension](https://marketplace.visualstudio.com/items?itemName=yzhang.markdown-all-in-one) to generate TOC.
1. **Solution Overview** - Provide the background of the solution (i.e. What problem are you trying to solve?), solution architecture and key technologies used.
1. **Key Learnings** - These are the key takeaways you want to impart to the engineer trying out the sample. For example, "Make your data pipelines replayable and idempotent".
1. **Key Concepts** - These are the DataOps and WAF concepts that the sample is showcasing. For example, "Continuous Integration". This will be the meat of your sample.
1. **How to use the sample** - A clear deployment instructions and all pre-requisites along with a list of deployed resources.
1. **Known Issues, Limitations and Workarounds** - Elaborate on any issues and deficiency in the provided solution the reader should be made aware of. Any key WAF concepts that the solution is **not** addressing that you particularly want to call out. Any workarounds in the deployment script.

#### Automated Deployment

> NOTE: This requirement is not yet consistently enforced but will eventually be required to facilitate automated testing of all deployment scripts of all samples.

Ensure you have a `deploy.sh` or `deploy.ps1` in the root of the sample as the entry point of the deployment of your sample.

## Contributing to an existing sample

**First**, Look through Github issues if there are any similar work in progress (ie. issues with PRs associated to them) to avoid duplicate efforts.

**Second**, Create a Github issue detailing your work using the "Feature Request" issue template. Tag the issue using the relevant label (ie. "single-tech: databricks", "e2e: fabric"). See "Labels" below.

**Third**, Develop your changes. If you are not a member of the Azure-Samples organization (Microsoft employees only), you will need to fork the repository. Otherwise, familiarize yourself with the Branching structure (see below). Every sample should come with developer setup information and most come with a Devcontainer.

**Fourth**, Raise a PR and fill up the PR template including associating it to the correct Github issue. Ensure you apply the correct label to the PR. This repo has a number of automated checks such as linting, link checks, and more. See [.github/workflows](/.github/workflows/) folder for details.

## Labels

Ensure you are applying the appropriate labels to issues.

Minimum **required** labels is either `e2e: <sample_name>` or `single-tech: <technology>`. **It is important the correct label is applied to ensure the issue is routed to the correct team backlog.**

It is also encouraged (not required) to label work related to key concepts i.e. `key-concept: load testing`.

View [existing labels](https://github.com/Azure-Samples/modern-data-warehouse-dataops/labels?sort=name-asc) for more information.

## Branching structure

Create a designated **feature branch** for the sample you will be building: `feat/<name-sample>`.

For individual developer branches, use: `developer_name/branch`.

Developers can also choose to fork the repo and work off that. Ensure your PR into the Feature Branch first before raising a PR into `main`.

Please delete branches after merging. Stale branches (no commits in last 120 days) maybe deleted without notice.

## Contributor License Agreement (CLA)

Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit [https://cla.opensource.microsoft.com](https://cla.opensource.microsoft.com).

When you submit a pull request, a CLA bot will automatically determine whether you need to provide
a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions
provided by the bot. You will only need to do this once across all repos using our CLA.
