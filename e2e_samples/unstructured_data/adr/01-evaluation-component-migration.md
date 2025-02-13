# Evaluation component migration

Proposal

## Context

The Unstructured Data Processing will leverage existing code that runs experiments and evaluates the results of said experiments. We will need to migrate this code as a sample into the modern data warehouse repo. The code consists of two Python scripts and several dependencies found within an orchestrator folder.

Additionally, the existing code currently uses Azure Machine Learning (AML) to host Databricks Mlflow. This sample will primarily focus on Databricks as its primary data processing technology, so this presents an opportunity to remove AML entirely in favor of Mlflow hosted on Databricks.

## Decision

The decision is to migrate all the code required to run the scripts that run experiments and evaluate their results. This migration will also include a follow-up user story to remove AML in favor of Databricks Mlflow, thereby completely eliminating the need for AML.

## Consequences

This change removes the dependency on AML and simplifies the tech stack at the cost of having the additional work of modifying the existing code.
