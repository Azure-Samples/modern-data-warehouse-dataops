import os
from dataclasses import dataclass
from pathlib import Path

DEFAULT_EVALUATORS_DIR = Path(__file__).absolute().parent.parent.joinpath("evaluators")
DEFAULT_RUN_OUTPUTS_DIR = Path(__file__).absolute().parent.parent.parent.joinpath("run_outputs")


@dataclass
class Config:
    """
    Config class to manage configuration settings for the application.

    Attributes:
        evaluators_dir (Path): Directory path for evaluators, which can be set via the
            environment variable 'EVALUATORS_DIR'. Defaults to 'DEFAULT_EVALUATORS_DIR'
            if the environment variable is not set.
        run_outputs_dir (Path): Directory path for run outputs, which can be set via the
            environment variable 'RUN_OUTPUTS_DIR'. Defaults to
            'DEFAULT_RUN_OUTPUTS_DIR' if the environment variable is not set.
    """

    evaluators_dir: Path = Path(os.environ.get("EVALUATORS_DIR", DEFAULT_EVALUATORS_DIR))
    run_outputs_dir: Path = Path(os.environ.get("RUN_OUTPUTS_DIR ", DEFAULT_RUN_OUTPUTS_DIR))
