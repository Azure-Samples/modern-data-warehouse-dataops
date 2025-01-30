import os
from datetime import datetime
from test.fabric_test_utils import get_item_id, get_workspace_id, run_job
from typing import Optional

import pytest


@pytest.fixture
def workspace_name() -> Optional[str]:
    return os.getenv("FABRIC_WORKSPACE_NAME")


@pytest.fixture
def lakehouse_name() -> Optional[str]:
    return os.getenv("FABRIC_LAKEHOUSE_NAME")


def test_setup(workspace_name: str, lakehouse_name: str) -> None:

    workspace_id = get_workspace_id(workspace_name)
    lakehouse_id = get_item_id(workspace_id, "Lakehouse", lakehouse_name)
    notebook_id = get_item_id(workspace_id, "Notebook", "nb-setup")

    assert notebook_id is not None

    current_time = datetime.now().strftime("%Y%m%d%H%M%S")
    payload = {
        "executionData": {
            "parameters": {
                "infilefolder": {"value": f"{current_time}", "type": "string"},
                "lakehouse_id": {"value": f"{lakehouse_id}", "type": "string"},
                "lakehouse_name": {"value": f"{lakehouse_name}", "type": "string"},
                "workspace_id": {"value": f"{workspace_id}", "type": "string"},
                "workspace_name": {"value": f"{workspace_name}", "type": "string"},
            }
        }
    }

    print(f"Running notebook {notebook_id} with payload {payload}")

    result = run_job(workspace_id, notebook_id, "RunNotebook", payload)
    assert result == "Completed"
