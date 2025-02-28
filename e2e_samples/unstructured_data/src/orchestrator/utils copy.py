import importlib
from copy import deepcopy
from datetime import datetime
from pathlib import Path
from typing import Any, Callable, Optional

from orchestrator.config import Config
from orchestrator.types import NotGiven


def new_run_id() -> str:
    return datetime.now().strftime("%Y%m%d%H%M%S")


def get_output_dirs_by_run_id(run_id: str, root_dir: Path = Config.run_outputs_dir) -> list[Path]:
    """
    Retrieve all directories matching the given run ID within the specified
    root directory.

    Args:
        run_id (str): The run ID to search for.
        root_dir (Path, optional): The root directory to search within.
        Defaults to Config.run_outputs_dir.

    Returns:
        list[Path]: A list of Path objects representing directories that
            match the run ID.
    """
    # get all directories equal to the run_id
    dirs: list[Path] = []
    for path in root_dir.rglob(run_id):
        if path.is_dir():
            dirs.append(path)
    return dirs


def merge_dicts(dict_1: dict, dict_2: dict) -> dict:
    """
    Merges two dictionaries recursively. If both dictionaries have a key with
    a dictionary as its value, the function will merge those dictionaries as well.
    If the same key has non-dictionary values in both dictionaries, the value from
    the second dictionary will overwrite the value from the first dictionary.
    Args:
        dict_1 (dict): The first dictionary to merge.
        dict_2 (dict): The second dictionary to merge.
    Returns:
        dict: A new dictionary containing the merged contents of dict_1 and dict_2.
    """

    def merge(d1: Any, d2: Any) -> Any:
        if isinstance(d2, dict):
            for k, v in d2.items():
                if k in d1:
                    if isinstance(d1[k], dict) and isinstance(v, dict):
                        d1[k] = merge(d1[k], v)
                    elif isinstance(v, NotGiven):
                        d1[k] = d1[k]
                    else:
                        d1[k] = v
                else:
                    d1[k] = v
        else:
            d1 = d2
        return d1

    return merge(deepcopy(dict_1), deepcopy(dict_2))


def load_instance(module: str, class_name: str, init_args: Optional[dict] = None) -> Callable:
    if init_args is None:
        init_args = {}
    for k, v in init_args.items():
        if isinstance(v, dict):
            type = v.get("type")
            if type == "load_from_module":
                module_to_load = v.get("module")
                class_name_to_load = v.get("class_name")
                init_args_to_load = v.get("init_args")
                if module_to_load is not None and class_name_to_load is not None:
                    init_args[k] = load_instance(module_to_load, class_name_to_load, init_args_to_load)

    imported_module = importlib.import_module(module)
    cls = getattr(imported_module, class_name)
    return cls(**init_args)


def flatten_dict(d: dict, parent_key: str = "", sep: str = ".") -> dict:
    items: list = []
    for k, v in d.items():
        new_key = f"{parent_key}{sep}{k}" if parent_key else k
        if isinstance(v, dict):
            items.extend(flatten_dict(v, new_key, sep=sep).items())
        else:
            items.append((new_key, v))
    return dict(items)
