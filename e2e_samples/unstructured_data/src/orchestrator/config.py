import os
from dataclasses import dataclass
from pathlib import Path

from dotenv import load_dotenv

load_dotenv()

REPO_ROOT = Path(__file__).absolute().parent.parent.parent
SRC_DIR = REPO_ROOT.joinpath("src")


@dataclass
class Config:
    """
    Config class to manage configuration settings for the application.

    Attributes:
        evaluators_dir (Path): Directory path for evaluators, which can be set via the
            environment variable 'EVALUATORS_DIR'. Defaults to
            '<repo-root>/src/evaluators' if the environment variable is not set.
        experiments_dir (Path): Directory path for experiments, which can be set via the
            environment variable 'EXPERIMENTS_DIR'. Defaults to
            '<repo-root>/src/experiments' if the environment variable is not set.
        run_outputs_dir (Path): Directory path for run outputs, which can be set via the
            environment variable 'RUN_OUTPUTS_DIR'. Defaults to
            '<repo-root>/run_outputs' if the environment variable is not set.
    """

    evaluators_dir: Path = Path(os.environ.get("EVALUATORS_DIR", SRC_DIR.joinpath("evaluators")))
    experiments_dir: Path = Path(os.environ.get("EXPERIMENTS_DIR", SRC_DIR.joinpath("experiments")))
    run_outputs_dir: Path = Path(os.environ.get("RUN_OUTPUTS_DIR ", REPO_ROOT.joinpath("run_outputs")))
