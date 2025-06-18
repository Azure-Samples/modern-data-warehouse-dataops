"""
Feature set retrieval utilities for Azure ML managed feature store.

This module provides functions and classes for retrieving feature sets
from Azure ML managed feature store and setting up clients.
"""

from typing import Any, Dict, Optional

try:
    from azure.ai.ml import MLClient
    from azure.identity import ClientSecretCredential
    from azureml.featurestore import FeatureStoreClient
except ImportError:
    # For environments where Azure ML packages are not available
    MLClient = None
    ClientSecretCredential = None
    FeatureStoreClient = None

try:
    from notebookutils import mssparkutils

    spark = mssparkutils.spark
except ImportError:
    # Fallback for testing environments
    try:
        from pyspark.sql import SparkSession

        spark = SparkSession.getActiveSession()
    except ImportError:
        spark = None


class FeatureStoreManager:
    """Manages feature store connections and operations."""

    def __init__(self, client_secret: str = ""):
        """Initialize the feature store manager."""
        if spark is None:
            raise RuntimeError("Spark session is required for feature store operations")

        # Get configuration from Spark
        self.featurestore_subscription_id = spark.conf.get("spark.fsd.subscription_id", "")
        self.featurestore_resource_group_name = spark.conf.get("spark.fsd.rg_name", "")
        self.featurestore_name = spark.conf.get("spark.fsd.name", "")
        self.fabric_tenant = spark.conf.get("spark.fsd.fabric.tenant", "")

        # Service principal credentials
        self.client_id = spark.conf.get("spark.fsd.client_id", "")
        self.tenant_id = spark.conf.get("spark.fsd.tenant_id", "")
        self.client_secret = client_secret

        # Feature set names
        self.nyctaxi_featureset_name = "nyctaxi"
        self.nycweather_featureset_name = "nycweather"

        # Initialize clients
        self._credential = None
        self._featurestore_client = None
        self._ml_client = None
        self._all_featuresets: Optional[Dict[str, str]] = None

    @property
    def credential(self) -> Optional[Any]:
        """Get or create Azure credential."""
        if self._credential is None and ClientSecretCredential is not None:
            self._credential = ClientSecretCredential(
                tenant_id=self.tenant_id, client_id=self.client_id, client_secret=self.client_secret
            )
        return self._credential

    @property
    def featurestore_client(self) -> Optional[Any]:
        """Get or create feature store client."""
        if self._featurestore_client is None and FeatureStoreClient is not None:
            self._featurestore_client = FeatureStoreClient(
                credential=self.credential,
                subscription_id=self.featurestore_subscription_id,
                resource_group_name=self.featurestore_resource_group_name,
                name=self.featurestore_name,
            )
        return self._featurestore_client

    @property
    def ml_client(self) -> Optional[Any]:
        """Get or create ML client."""
        if self._ml_client is None and MLClient is not None:
            self._ml_client = MLClient(
                self.credential,
                self.featurestore_subscription_id,
                self.featurestore_resource_group_name,
                self.featurestore_name,
            )
        return self._ml_client

    @property
    def all_featuresets(self) -> Dict[str, str]:
        """Get all available feature sets and their latest versions."""
        if self._all_featuresets is None:
            self._all_featuresets = {}
            if self.ml_client is not None:
                try:
                    for fset in self.ml_client.feature_sets.list():
                        self._all_featuresets[fset.name] = fset.latest_version
                except Exception as e:
                    print(f"Warning: Could not list feature sets: {e}")
                    # Provide default values
                    self._all_featuresets = {self.nyctaxi_featureset_name: "1", self.nycweather_featureset_name: "1"}
            else:
                # Fallback when Azure ML is not available
                self._all_featuresets = {self.nyctaxi_featureset_name: "1", self.nycweather_featureset_name: "1"}
        return self._all_featuresets

    def get_feature_dataframes(self) -> Optional[tuple]:
        """Retrieve feature dataframes from the feature store."""
        if self.featurestore_client is None:
            raise RuntimeError("FeatureStoreClient is not available")

        try:
            # Get NYC taxi features
            nyctaxi_df = self.featurestore_client.feature_sets.get(
                self.nyctaxi_featureset_name, self.all_featuresets[self.nyctaxi_featureset_name]
            ).to_spark_dataframe()

            # Get NYC weather features
            nycweather_df = self.featurestore_client.feature_sets.get(
                self.nycweather_featureset_name, self.all_featuresets[self.nycweather_featureset_name]
            ).to_spark_dataframe()

            return nyctaxi_df, nycweather_df

        except Exception as e:
            print(f"Error retrieving feature dataframes: {e}")
            return None, None


def setup_feature_store_client(client_secret: str = "") -> FeatureStoreManager:
    """
    Set up feature store client with configuration from Spark.

    Args:
        client_secret: Azure service principal client secret

    Returns:
        FeatureStoreManager instance
    """
    return FeatureStoreManager(client_secret=client_secret)


def get_featurestore_config() -> Dict[str, str]:
    """
    Get feature store configuration from Spark configuration.

    Returns:
        Dictionary containing feature store configuration
    """
    if spark is None:
        return {}

    return {
        "subscription_id": spark.conf.get("spark.fsd.subscription_id", ""),
        "resource_group": spark.conf.get("spark.fsd.rg_name", ""),
        "featurestore_name": spark.conf.get("spark.fsd.name", ""),
        "fabric_tenant": spark.conf.get("spark.fsd.fabric.tenant", ""),
        "client_id": spark.conf.get("spark.fsd.client_id", ""),
        "tenant_id": spark.conf.get("spark.fsd.tenant_id", ""),
    }
