# Linting, Formatting & Other pre-commit Checks

Make sure that you have followed steps in [Getting Started](../CONTRIBUTING.md#getting-started) Section

---

- Any changes which gets commit'd to GIT will trigger pre-commit checks. The output will look like below:

   ![pre-commit-1](images/pre_commit_1_git_commit.png)

---

- To run these checks manually, you may use below command. The output will look like below:

   ```python
   pre-commit run --all-files
   ```

   ![pre-commit-2](images/pre_commit_2_manual_run.png)  

---

- To run specific pre-commit check manually, you may do so as follows

   ```python
   # pre-commit run <pre-commit-id> <folder/file>
   # e.g
   pre-commit run black --all-files
   pre-commit run black <folder or file>
   pre-commit run nbqa-mypy --all-files
   pre-commit run terraform_tflint --all-files
   ```

---

- To bypass running pre-commit checks in local but still pushing code to GIT. You may use below command

   ```bash
   git add . && git commit -m "code changes" --no-verify
   ```
