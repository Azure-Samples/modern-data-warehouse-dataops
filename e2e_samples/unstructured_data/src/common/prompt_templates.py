from pathlib import Path

from common.file_utils import read_file
from jinja2 import Template


def load_template(path: str | Path) -> Template:
    txt = read_file(path)
    return Template(txt)
