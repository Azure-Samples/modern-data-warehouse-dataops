.PHONY: help
.DEFAULT_GOAL := help

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("%-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT

help:
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

uploaddatabricks: ## Uploads notebooks to databricks workspace
	databricks workspace import_dir --overwrite . $(DATABRICKS_WORKSPACE_UPLOAD_PATH)/

downloaddatabricks: ## Downloads notebooks to databricks workspace
	databricks workspace export_dir --overwrite $(DATABRICKS_WORKSPACE_UPLOAD_PATH)/ .