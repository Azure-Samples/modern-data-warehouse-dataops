from dataclasses import dataclass
from pathlib import Path

from orchestrator.env import EVALUATORS_DIR, EXPERIMENTS_DIR, RUN_OUTPUTS_DIR

SRC_DIR = Path(__file__).absolute().parent.parent


@dataclass
class Config:
    """
    Config class to manage configuration settings for the application.

    Attributes:
        evaluators_dir (Path): Directory path for evaluators. Set with the environment variable 'EVALUATORS_DIR'.
        experiments_dir (Path): Directory path for experiments. Set with the environment variable 'EXPERIMENTS_DIR'.
        run_outputs_dir (Path): Directory path for run outputs. Set with the environment variable 'RUN_OUTPUTS_DIR'.
    """

    evaluators_dir: Path = Path(EVALUATORS_DIR) if EVALUATORS_DIR is not None else SRC_DIR.joinpath("evaluators")
    experiments_dir: Path = Path(EXPERIMENTS_DIR) if EXPERIMENTS_DIR is not None else SRC_DIR.joinpath("experiments")
    run_outputs_dir: Path = (
        Path(RUN_OUTPUTS_DIR) if RUN_OUTPUTS_DIR is not None else SRC_DIR.parent.joinpath("run_outputs")
    )
