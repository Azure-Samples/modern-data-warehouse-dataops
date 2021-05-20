from setuptools import find_packages, setup
from src import __version__

setup(
    name="mlflowsample",
    packages=find_packages(),
    setup_requires=["wheel"],
    version=__version__
)