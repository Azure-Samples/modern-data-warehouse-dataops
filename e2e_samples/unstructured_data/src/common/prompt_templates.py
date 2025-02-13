from pathlib import Path
from typing import Any, Optional

from jinja2 import Template
from orchestrator.file_utils import load_file, read_file


def _get_path(variable: Any) -> Optional[str]:
    if isinstance(variable, dict):
        path = variable.get("path")
        if path is None:
            raise AttributeError(f"Template variable is missing 'path' key. Received: {variable}")
        return path
    return None


def _load_variables(
    variables: dict,
    templates_dir: Optional[Path] = None,
) -> dict:
    result = {}
    for k, v in variables.items():
        path = _get_path(v)
        if path is not None:
            if templates_dir is not None:
                fullpath = templates_dir.joinpath(Path(path))
            else:
                fullpath = Path(path)
            result[k] = load_file(fullpath)
        else:
            result[k] = v
    return result


def get_rendered_prompt_template(
    variables: Optional[dict] = None,
    templates_dir: Optional[str] = None,
    path: Optional[str] = None,
    prompt: Optional[str] = None,
    **kwargs: Any,
) -> str:
    if variables is None:
        variables = {}
    template_dir_path = Path(templates_dir) if templates_dir is not None else None

    if path is not None:
        if template_dir_path is not None:
            path = str(template_dir_path.joinpath(path))
        source = read_file(path)
    elif prompt is not None:
        source = prompt
    else:
        raise AttributeError("template config must have either a 'path' or 'prompt' key")

    template_variables = _load_variables(variables, template_dir_path)
    template = Template(source)
    return template.render(template_variables)
