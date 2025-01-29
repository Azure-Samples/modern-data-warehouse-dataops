# Databricks for Compute

Proposal

## Context

The Unstructured Data Processing end-to-end reference implementation needs some kind of compute to process data. Because the Modern Data Estate repo is primarily focused on data processing platform technologies like Databricks, Synapse, and Fabric, this end-to-end reference implementation needs to choose one of those three options.

Databricks has a mature Infrastructure as Code capabilities and novel Generative AI capabilities that make it the choice of this sample.

## Decision

This end-to-end reference implementation will use Databricks for its compute needs where possible.

An exception will be made for any dependencies outside of this solution, like resources deployed in [the Citation Tool](https://github.com/billba/excitation).

## Consequences

The reference implementation will focus on data engineering patterns to support the Gen AI application.
