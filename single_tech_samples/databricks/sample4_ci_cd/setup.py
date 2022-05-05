from setuptools import find_packages, setup

setup(
    name="sparkapp_project",
    packages=find_packages(exclude=["tests", "tests.*"]),
    setup_requires=["wheel"],
    version="0.0.1",
    description="Databricks SparkApp Project",
    author="",
)
