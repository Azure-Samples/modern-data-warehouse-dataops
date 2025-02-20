import json
from pathlib import Path

import yaml


def load_json_file(path: str | Path) -> dict:
    with open(path) as f:
        return json.load(f)


def load_yaml_file(path: str | Path) -> dict:
    with open(path) as f:
        return yaml.safe_load(f)


def read_file(path: str | Path) -> str:
    with open(path) as f:
        return f.read()


def load_file(path: str | Path) -> dict | str:
    str_path = str(path)
    if str_path.endswith(".json"):
        return load_json_file(path)
    elif str_path.endswith((".yaml", "yml")):
        return load_yaml_file(path)
    else:
        return read_file(path)


def load_jsonl_file(path: str | Path) -> list:
    data_lines = []
    with open(path) as f:
        for line in f:
            data_lines.append(json.loads(line))
    return data_lines


def write_jsonl_file(path: str | Path, data: list, mode: str = "a") -> None:
    with open(path, mode) as f:
        for d in data:
            f.write(json.dumps(d) + "\n")


def write_json_file(path: str | Path, data: dict) -> None:
    with open(path, "w") as f:
        json.dump(data, f)
