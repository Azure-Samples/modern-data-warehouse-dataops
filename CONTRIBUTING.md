# Contributing to Modern Data Estate

Thank you for considering contributing to Modern Data Estate! This guide provides all the necessary steps to get started.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Linting, Formatting & Other pre-commit checks](./docs/linting-guide.md)

## Code of Conduct

We expect all contributors to adhere to our [Code of Conduct](./CODE_OF_CONDUCT.md).

## Getting Started

- Clone the repository:

   ```bash
   git clone <github link of repository>
   cd repository_folder
   ```

- Run below steps:

    ```python
    # setup venv
    python -m venv .venv

    # activate venv
    source .venv/bin/activate

    # install necessary development libraries
    pip install -e .[dev]

    # install pre-commit
    pre-commit install
    ```