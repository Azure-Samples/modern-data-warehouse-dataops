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
        evaluators_dir (Path): Directory path for evaluators. Set with the environment variable 'EVALUATORS_DIR'.
        experiments_dir (Path): Directory path for experiments. Set with the environment variable 'EXPERIMENTS_DIR'.
        run_outputs_dir (Path): Directory path for run outputs. Set with the environment variable 'RUN_OUTPUTS_DIR'.
    """

    evaluators_dir: Path = Path(os.environ.get("EVALUATORS_DIR", SRC_DIR.joinpath("evaluators")))
    experiments_dir: Path = Path(os.environ.get("EXPERIMENTS_DIR", SRC_DIR.joinpath("experiments")))
    run_outputs_dir: Path = Path(os.environ.get("RUN_OUTPUTS_DIR ", REPO_ROOT.joinpath("run_outputs")))
