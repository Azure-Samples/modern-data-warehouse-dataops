"""
Fabric-specific utilities for working with Microsoft Fabric OneLake.

This module provides functions for getting OneLake information and
other Fabric-specific operations.
"""

import re
from typing import Tuple

try:
    from notebookutils import mssparkutils
except ImportError:
    # For environments where notebookutils is not available
    mssparkutils = None


def get_onelake_info() -> Tuple[str, str, str]:
    """
    Get Fabric OneLake tenant, workspace ID and lakehouse ID from current attached lakehouse.

    Returns:
        Tuple of (fabric_onelake_tenant, fabric_workspace_id, fabric_lakehouse_id)
    """
    if mssparkutils is None:
        # Return empty strings when mssparkutils is not available
        return "", "", ""

    mount_source = ""
    fabric_onelake_tenant = ""
    fabric_workspace_id = ""
    fabric_lakehouse_id = ""

    try:
        mount_point_infos = mssparkutils.fs.mounts()

        for mount_point_info in mount_point_infos:
            if mount_point_info.localPath == "/lakehouse/default":
                mount_source = mount_point_info.source
                break

        if mount_source:
            fabric_onelake_tenant = mount_source.split(".dfs.fabric.microsoft.com")[0].split("@")[1]

            workspace_match = re.search("abfss://(.*)@", mount_source, flags=0)
            if workspace_match:
                fabric_workspace_id = workspace_match.group(1)

            lakehouse_match = re.search("dfs.fabric.microsoft.com/(.*)$", mount_source, flags=0)
            if lakehouse_match:
                fabric_lakehouse_id = lakehouse_match.group(1)

    except Exception as e:
        print(f"Warning: Could not get OneLake info: {e}")

    return fabric_onelake_tenant, fabric_workspace_id, fabric_lakehouse_id


def get_notebook_context() -> dict:
    """
    Get current notebook context information.

    Returns:
        Dictionary containing notebook context information
    """
    if mssparkutils is None:
        return {}

    try:
        context = mssparkutils.notebook.nb.context
        return {
            "currentWorkspaceId": context.get("currentWorkspaceId", ""),
            "currentNotebookId": context.get("currentNotebookId", ""),
            "currentNotebookName": context.get("currentNotebookName", ""),
        }
    except Exception as e:
        print(f"Warning: Could not get notebook context: {e}")
        return {}


def get_fabric_urls(workspace_id: str, fabric_tenant: str = "msit") -> dict:
    """
    Generate Fabric URLs for various resources.

    Args:
        workspace_id: The Fabric workspace ID
        fabric_tenant: The Fabric tenant (default: "msit")

    Returns:
        Dictionary containing various Fabric URLs
    """
    base_url = f"https://{fabric_tenant}.powerbi.com/groups/{workspace_id}"

    return {
        "workspace": base_url,
        "notebooks": f"{base_url}/synapsenotebooks",
        "ml_experiments": f"{base_url}/mlexperiments",
        "ml_models": f"{base_url}/mlmodels",
    }
