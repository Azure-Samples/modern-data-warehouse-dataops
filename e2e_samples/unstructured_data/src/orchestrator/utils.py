from copy import deepcopy
from datetime import datetime
from pathlib import Path
from typing import Any

from orchestrator.config import Config


def new_run_id() -> str:
    return datetime.now().strftime("%Y%m%d%H%M%S")


def get_output_dirs_by_run_id(run_id: str) -> list[Path]:
    # get all directories equal to the run_id
    dirs: list[Path] = []
    for path in Config.run_outputs_dir.rglob(run_id):
        if path.is_dir():
            dirs.append(path)
    return dirs


def merge_dicts(dict_1: dict, dict_2: dict) -> dict:
    """
    Merges two dictionaries recursively. Values from the second dictionary take
        precedence.
    If both dictionaries have a dictionary at the same key, those dictionaries are
        merged recursively.
    If both dictionaries have a list at the same key, those lists are concatenated.
    In all other cases of a duplicate key, the value from dict_2 will be used.
    Args:
        dict_1 (dict): The first dictionary to merge.
        dict_2 (dict): The second dictionary to merge. Values from this dictionary
            take precedence.
    Returns:
        dict: A new dictionary containing the merged values.
    """

    def merge(d1: Any, d2: Any) -> Any:
        if isinstance(d2, dict):
            for k, v in d2.items():
                if k in d1:
                    if isinstance(d1[k], dict) and isinstance(v, dict):
                        d1[k] = merge(d1[k], v)
                    elif isinstance(d1[k], list) and isinstance(v, list):
                        d1[k].extend(v)
                    else:
                        d1[k] = v
                else:
                    d1[k] = v

        elif isinstance(d1, list) and isinstance(d2, list):
            d1.extend(d2)
        else:
            d1 = d2
        return d1

    return merge(deepcopy(dict_1), dict_2)
