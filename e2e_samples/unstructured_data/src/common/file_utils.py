from pathlib import Path


def read_file(path: Path | str) -> str:
    with open(path) as f:
        return f.read()
