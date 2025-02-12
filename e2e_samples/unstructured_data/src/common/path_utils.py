from pathlib import Path


class RepoPaths:
    repo = Path(__file__).absolute().parent.parent.parent
    experiments = repo.joinpath("src", "experiments")
    data = repo.joinpath("data")
    run_outputs = repo.joinpath("run_outputs")

    @classmethod
    def experiment_config_path(
        cls,
        experiment_name: str,
        experiment_config_path: str = "config/experiment.yaml",
    ) -> Path:
        return cls.experiments.joinpath(experiment_name, experiment_config_path)

    @classmethod
    def data_path(cls, name: str) -> Path:
        return cls.data.joinpath(name)
