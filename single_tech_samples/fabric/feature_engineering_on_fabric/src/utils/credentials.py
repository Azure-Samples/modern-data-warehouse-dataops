"""
Credentials module for Azure authentication in Fabric notebooks.

This module provides a class to access Azure credentials from Spark configuration.
"""

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


class SPCredentials:
    """Service Principal credentials from Spark configuration."""

    @property
    def CLIENT_ID(self) -> str:
        """Get client ID from Spark configuration."""
        if spark:
            return spark.conf.get("spark.fsd.client_id", "")
        return ""

    @property
    def CLIENT_SECRET(self) -> str:
        """Get client secret from Spark configuration."""
        if spark:
            return spark.conf.get("spark.fsd.client_secret", "")
        return ""

    @property
    def TENANT_ID(self) -> str:
        """Get tenant ID from Spark configuration."""
        if spark:
            return spark.conf.get("spark.fsd.tenant_id", "")
        return ""


def get_purview_account() -> str:
    """Get Purview account name from Spark configuration."""
    if spark:
        return spark.conf.get("spark.fsd.purview.account", "")
    return ""
