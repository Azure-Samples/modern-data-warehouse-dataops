"""
This script runs experiments based on specified configurations and writes
the results to a file.
This script assumes that the experiment data contains all data needed for evaluations.

Usage:
    python ./scripts/run_experiments.py \
        -e <experiment-config-path> \
        -v <path-from-variants-dir-1> <path-from-variants-dir-2> \
        -i <run-id> -d <path-in-data-dir> \
        -t <app_insights|local>

Options:
    -e, --experiment-config-path <experiment-config-path>
        The path to the experiment config from the experiments directory.
        Defaults to "llm_citation_generator/config/experiment.yaml".
    -v, --variants <paths>
        A list of variant paths. Paths are relative from the variants directory for the experiment.
    -i, --run-id <run-id>
        The run id. Default is timestamp: YmdHMS.
    -d, --data-path <path>
        The path to the data file in the data directory.
    -t, --telemetry <app_insights|local>
        The telemetry configuration. Can be "app_insights" or "local". If not provided, telemetry is not set up.
        If provided, default value is 'local'.

Example:
    python ./scripts/run_experiments.py \
        -e llm_citation_generator \
        -v revenue-FY24Q3.yaml \
        -d test-data.jsonl \
        -t app_insights

Environment Variables:
    This script uses environment variables defined in a .env file
    a template is provided at e2e_samples/unstructured_data/src/.envtemplate
"""

if __name__ == "__main__":

    import argparse
    import logging
    from pathlib import Path

    from orchestrator.run_experiment import run_experiments
    from orchestrator.telemetry_utils import configure_telemetry

    logging.basicConfig()
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.INFO)

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-e",
        "--experiment-config-path",
        required=False,
        default="llm_citation_generator/config/experiment.yaml",
        help="The config path of the experiment in the experiments directory",
    )
    parser.add_argument(
        "-v",
        "--variants",
        nargs="*",
        required=False,
        default=["total-revenue/1.yaml", "earnings-per-share/1.yaml"],
        help="A list of variants paths. Paths are relative from the \
            variants (questions) directory for the experiment",
    )
    parser.add_argument(
        "-r",
        "--run-id",
        required=False,
        help="The run id. For citation generator, this will be the form suffix. \
            Default is a timestamp: YmdHMS. Supply this to run against an existing \
            form wihich ends with the run id",
    )
    parser.add_argument(
        "-d",
        "--data-filename",
        required=False,
        default="test-data.jsonl",
        help="The data filename in the ./data directory",
    )
    parser.add_argument(
        "-t",
        "--telemetry",
        required=False,
        nargs="?",
        choices=["app_insights", "local"],
        const="local",
        help="The environment for sending telemtry. Defaults to local. Not providing \
            the flag will not set up telemetry",
    )
    args = parser.parse_args()

    telemetry = args.telemetry.upper() if args.telemetry is not None else None
    configure_telemetry(telemetry)

    data_path = Path(__file__).absolute().parent.parent.joinpath("data").joinpath(args.data_filename)

    run_results = run_experiments(
        config_filepath=args.experiment_config_path,
        variants=args.variants,
        run_id=args.run_id,
        data_path=data_path,
        write_to_file=True,
        is_eval_data=True,
    )

    for r in run_results.results:
        logger.info(r)

    logger.info(f"Run ID: {run_results.run_id}")
