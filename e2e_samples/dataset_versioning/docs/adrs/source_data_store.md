# Source Data Store

## Status

Decided

## Context

In order to demonstrate data versioning, we need to pull from a data store. There is no existing _source_ data store, so we need to decide which technology we would like to use.

## Decision

We have decided on `Azure SQL` as our data store.

## Consequences

* `Azure SQL` provides an inexpensive solution.
* Reduces the amount of unfamiliar technology introduced into this sample.
* SQL databases are a commonly used data source for Data Engineers.
* Existing patterns for working with SQL sources in `Azure Databricks`.
