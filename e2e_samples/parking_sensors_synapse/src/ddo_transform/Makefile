.PHONY: clean clean-test clean-pyc clean-build docs help
.DEFAULT_GOAL := help

PYTHON_PACKAGE := ddo_transform

define BROWSER_PYSCRIPT
import os, webbrowser, sys

try:
	from urllib import pathname2url
except:
	from urllib.request import pathname2url

webbrowser.open("file://" + pathname2url(os.path.abspath(sys.argv[1])))
endef
export BROWSER_PYSCRIPT

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
	match = re.match(r'^([a-zA-Z_-]+):.*?## (.*)$$', line)
	if match:
		target, help = match.groups()
		print("%-20s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT

BROWSER := python -c "$$BROWSER_PYSCRIPT"

help:
	@python -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

clean: clean-build clean-pyc clean-test ## remove all build, test, coverage and Python artifacts

clean-build: ## remove build artifacts
	rm -fr build/
	rm -fr dist/
	rm -fr .eggs/
	find . -name '*.egg-info' -exec rm -fr {} +
	find . -name '*.egg' -exec rm -f {} +

clean-pyc: ## remove Python file artifacts
	find . -name '*.pyc' -exec rm -f {} +
	find . -name '*.pyo' -exec rm -f {} +
	find . -name '*~' -exec rm -f {} +
	find . -name '__pycache__' -exec rm -fr {} +

clean-test: ## remove test and coverage artifacts
	rm -fr .tox/
	rm -f .coverage
	rm -fr htmlcov/
	rm -fr .pytest_cache

lint: ## check style with flake8
	flake8 $(PYTHON_PACKAGE)

test: ## run tests quickly with the default Python
	py.test

test-all: ## run tests on every Python version with tox
	tox

coverage: ## check code coverage quickly with the default Python
	coverage run --source $(PYTHON_PACKAGE) -m pytest
	coverage report -m
	coverage html
	$(BROWSER) htmlcov/index.html

release: dist ## package and upload a release
	twine upload dist/*

dist: clean ## builds source and wheel package
	sed -i "s/{{version}}/$(PACKAGE_VERSION)/g" $(PYTHON_PACKAGE)/__init__.py
	python setup.py sdist
	python setup.py bdist_wheel
	ls -l dist

install: clean ## install the package to the active Python's site-packages
	python setup.py install

installedit: clean ## install the package while dynamically picking up changes to source files
	pip install --editable .

uploaddatabricks: dist ## uploads package to databricks to DATABRICKS_DBFS_PACKAGE_UPLOAD_PATH
	package_name="$$(find dist/*.whl -printf "%f\n")"; \
	databricks fs cp --overwrite dist/"$$package_name" "$(DATABRICKS_DBFS_PACKAGE_UPLOAD_PATH)/$$package_name";\

installdatabricks: dist uploaddatabricks ## install the package in databricks
	package_name="$$(find dist/*.whl -printf "%f\n")"; \
	databricks libraries install --cluster-id $(DATABRICKS_CLUSTER_ID) --whl "$(DATABRICKS_DBFS_PACKAGE_UPLOAD_PATH)/$$package_name"
	databricks clusters restart --cluster-id $(DATABRICKS_CLUSTER_ID)