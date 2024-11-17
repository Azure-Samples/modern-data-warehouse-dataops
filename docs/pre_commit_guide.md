
# Pre-commit Guide (Formatting, Linting & Other code quality checks) <!-- omit in toc -->

This guide explains how to set up and use the pre-commit hooks configured in this repository. These hooks help ensure code quality and consistency by automatically checking and formatting code before it is committed.

**Note:** These are currently enabled only on [e2e_samples/fabric_dataops_sample](../e2e_samples/fabric_dataops_sample/).

## Table of Contents <!-- omit in toc -->

- [Introduction](#introduction)
- [Installation](#installation)
  - [Contributors using Dev Container Setup](#contributors-using-dev-container-setup)
  - [Contributors using Local Setup](#contributors-using-local-setup)
- [Configuration](#configuration)
- [Usage](#usage)
  - [On Every Commit](#on-every-commit)
  - [Running All Hooks Manually](#running-all-hooks-manually)
  - [Running a Specific Hook](#running-a-specific-hook)
- [List of Hooks](#list-of-hooks)
- [Integration with GitHub Actions](#integration-with-github-actions)
- [Troubleshooting](#troubleshooting)
  - [Common Issues](#common-issues)

## Introduction

We use **pre-commit hooks** to ensure code quality and consistency. Pre-commit hooks are scripts that run automatically before each commit to catch common issues like syntax errors, formatting problems, and security vulnerabilities. This repository uses a variety of hooks to maintain code quality.

## Installation

### Contributors using Dev Container Setup

If you are using Dev Container setup, all these are pre-configured/pre-installed for you.

### Contributors using Local Setup

- Clone the repository:

   ```bash
   git clone <github link of project>
   cd project-folder
   ```

- Run below steps:

    ```python
    # setup venv
    python -m venv .venv

    # activate venv
    source .venv/bin/activate

    # install necessary development libraries
    pip install --upgrade pip setuptools wheel
    pip install -e .[dev]

    # install pre-commit
    pre-commit install
    ```

- Apart from these, there are few tools you need to install on your local machine (like Terraform,TFLint, Trivy). Please refer to the tool documentation to get installation instructions depending on your Operating System. Sample Ubuntu instructions can be found inside [Dev Container's Docker File](../e2e_samples/fabric_dataops_sample/.devcontainer/Dockerfile)

These steps will set up the hooks to run automatically before every commit.

## Configuration

The pre-commit hooks are configured in the [`.pre-commit-config.yaml`](../.pre-commit-config.yaml) file. This file specifies the repositories and hooks to be used, along with their versions and any specific arguments.

In addition to [`.pre-commit-config.yaml`](../.pre-commit-config.yaml), we use [`pyproject.toml`](../pyproject.toml) for configuring tools like **Black**, **isort**, **Ruff**, and **Mypy**. This file allows us to define custom inclusions, exclusions, and other tool-specific settings.

## Usage

### On Every Commit

Once installed, the pre-commit hooks will run automatically on every commit. If any hook fails, the commit will be aborted, and you will need to fix the issues before committing again.

```bash
git commit -m "Your commit message"
```

If any checks fail, the commit will be blocked. You need to fix the issues and try committing again.

For example:

![pre-commit-1](images/pre_commit_1_git_commit.png)

### Running All Hooks Manually

To run all configured hooks manually on the entire codebase:

```bash
pre-commit run --all-files
```

For example:

![pre-commit-2](images/pre_commit_2_manual_run.png)

### Running a Specific Hook

To run a specific hook, use:

```bash
pre-commit run <hook-id> --all-files
```

For example:

```bash
# To invoke black formatting on all .py files
pre-commit run black --all-files
# To invoke terraform linting on all .tf files
pre-commit run terraform_tflint --all-files
```

## List of Hooks

Below is a list of the currently configured hooks with brief descriptions. **Note** that this list may change or evolve as the repository and workflows are updated.

1. **General Checks:**
   - `no-commit-to-branch`: Prevents committing directly to the `main` branch.
   - `check-merge-conflict`: Checks for unresolved merge conflicts.
   - `trailing-whitespace`, `end-of-file-fixer`, `mixed-line-ending`: Enforces consistent whitespace formatting.
   - `check-ast`, `check-json`, `check-toml`, `check-yaml`: Validates syntax for various file types.
   - `detect-private-key`: Detects accidental inclusion of private keys.
   - `check-added-large-files`: Prevents adding files larger than 1 MB.

2. **Python Code Formatting:**
   - `isort`: Sorts and organizes imports.
   - `black`: Formats Python code to follow PEP 8 guidelines.

3. **Python Linting:**
   - `ruff`: Lints Python code for style and syntax issues.
   - `mypy`: Performs static type checking.

4. **YAML and Markdown Linting:**
   - `yamllint`: Lints YAML files.
   - `markdownlint`: Lints Markdown files.

5. **Jupyter Notebook Checks:**
   - `nbqa-isort`, `nbqa-black`, `nbqa-ruff`, `nbqa-mypy`: Runs respective checks on Jupyter Notebooks.

6. **Shell Script Formatting:**
   - `shfmt`: Formats shell scripts.

7. **Terraform Checks:**
   - `terraform_fmt`, `terraform_tflint`, `terraform_validate`, `terraform_trivy`: Runs formatting, linting, validation, and vulnerability scans on Terraform files.

## Integration with GitHub Actions

In addition to running pre-commit hooks locally, these hooks are also invoked as part of the **GitHub Actions** [workflow](../.github/workflows/code_quality_checks.yaml). This ensures that code quality checks are performed automatically during pull requests and pushes to the repository.

## Troubleshooting

### Common Issues

1. **Pre-commit Hook Fails:**
   - Fix the reported issues and try committing again.
   - If needed, run the hooks manually to debug: `pre-commit run --all-files`.

2. **Hook Not Installed:**
   - Ensure you have installed the hooks with `pre-commit install`.

3. **Skipping Hooks:**
   - If necessary, you can bypass the hooks (not recommended) using:

     ```bash
     git commit --no-verify
     ```
