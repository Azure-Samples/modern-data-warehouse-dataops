from pathlib import Path


def read_file(path: str | Path) -> str:
    with open(path) as f:
        return f.read()
