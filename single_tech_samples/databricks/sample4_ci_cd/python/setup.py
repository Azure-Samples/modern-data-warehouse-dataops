from setuptools import find_packages, setup

setup(
    name="spark_python_project",
    packages=find_packages(exclude=["tests", "tests.*"]),
    setup_requires=["wheel"],
    version="0.0.1",
    description="Databricks Sample Project",
    author="",
)
