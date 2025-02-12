"""
This script runs experiments based on specified configurations and writes
the results to a file.
This script assumes that the experiment data contains all data needed for evaluations.

Usage:
    python ./scripts/run_experiments.py \
        -e <experiment-name> \
        -v <path-from-variants-dir-1> <path-from-variants-dir-2> \
        -i <run-id> -d <path-in-data-dir> \
        -t <app_insights|local>

    python ./scripts/run_experiments.py \
        -e llm_citation_generator \
        -v questions/total-assets/1.yaml questions/total-employees/1.yaml \
        -d citation-generator-truth.jsonl \
        -t app_insights

Options:
    -e, --experiment-name <experiment-name>   The directory name of the experiment.
                                                Default is "llm_citation_generator".
    -v, --variants <paths>                    A list of variant paths. Paths are
                                                relative from the variants directory
                                                for the experiment.
    -i, --run-id <run-id>                     The run id. Default is timestamp: YmdHMS.
    -d, --data-path <path>                    The path to the data file in the data
                                                directory.
    -t, --telemetry <app_insights|local>      The telemetry configuration. Can be
                                                "app_insights" or "local".

Example:
    python ./scripts/run_experiments.py \
        -e llm_citation_generator \
        -v questions/total-assets/1.yaml questions/total-employees/1.yaml \
        -d citation-generator-truth.jsonl \
        -t app_insights

Environment Variables:
    This script uses environment variables defined in a .env file.
    The .env file should be located in the root directory of the project.
"""

if __name__ == "__main__":
    import os
    import sys

    from dotenv import load_dotenv

    module_path = os.path.abspath(os.path.join("src"))
    if module_path not in sys.path:
        sys.path.append(module_path)
    load_dotenv(override=True)

    import argparse
    import logging

    from common.path_utils import RepoPaths
    from orchestrator.run_experiment import run_experiments
    from orchestrator.telemetry_utils import configure_telemetry

    logging.basicConfig()
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.INFO)

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-e",
        "--experiment-name",
        required=False,
        default="llm_citation_generator",
        help="The directory name of the experiment",
    )
    parser.add_argument(
        "-v",
        "--variants",
        nargs="*",
        required=False,
        default=[
            "questions/total-revenue/1.yaml",
        ],
        help="A list of variants paths. Paths are relative from the \
            variants directory for the experiment",
    )
    parser.add_argument(
        "-r",
        "--run-id",
        required=False,
        help="The run id. For Citation Generator, this will be the form suffix. \
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

    data_path = RepoPaths.data_path(args.data_filename)
    experiment_config = RepoPaths.experiment_config_path(args.experiment_name)

    run_results = run_experiments(
        config_filepath=experiment_config,
        variants=args.variants,
        run_id=args.run_id,
        data_path=data_path,
        output_dir=RepoPaths.run_outputs,
        is_eval_data=True,
    )

    for r in run_results.results:
        logger.info(r)
        print(r)

    logger.info(f"Run ID: {run_results.run_id}")
