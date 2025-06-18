"""
Feature store utilities for model training and feature management.

This module provides mock implementations and utility functions for
working with feature stores in the context of machine learning workflows.
"""

from typing import Any, Dict, List, Optional


class MockFeatureStore:
    """Mock feature store for testing and development purposes."""

    def __init__(self) -> None:
        self.feature_sets = self

    def get(self, name: str, version: str) -> Dict[str, Any]:
        """Mock implementation of feature set retrieval."""
        # Return a mock feature set object
        return {"name": name, "version": version, "features": [], "entities": []}


def fetch_logged_data(run_id: str) -> Dict[str, Any]:
    """Fetch logged data from MLflow for a given run ID."""
    try:
        import mlflow

        # Get run data from MLflow
        run = mlflow.get_run(run_id)

        logged_data: Dict[str, Any] = {}

        # Get parameters
        if run.data.params:
            logged_data["params"] = dict(run.data.params)

        # Get metrics
        if run.data.metrics:
            logged_data["metrics"] = dict(run.data.metrics)

        # Get tags
        if run.data.tags:
            logged_data["tags"] = dict(run.data.tags)

        # Get artifacts (simplified)
        try:
            artifacts = mlflow.artifacts.list_artifacts(run_id)
            logged_data["artifacts"] = [artifact.path for artifact in artifacts]
        except Exception:
            logged_data["artifacts"] = []

        return logged_data

    except Exception as e:
        print(f"Error fetching logged data: {e}")
        return {"error": str(e)}


def get_latest_model_version(model_name: str) -> Optional[str]:
    """Get the latest version of a registered model."""
    try:
        import mlflow
        from mlflow import MlflowClient

        client = MlflowClient()

        # Get the latest version of the model
        latest_versions = client.get_latest_versions(model_name, stages=["None", "Production", "Staging"])

        if latest_versions:
            # Return the highest version number
            versions = [int(version.version) for version in latest_versions]
            return str(max(versions))

        return None

    except Exception:
        return None
