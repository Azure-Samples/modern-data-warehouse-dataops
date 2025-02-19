"""
This script evaluates experiment results, writes the evaluation results to a
file and optionally uploads them to an Azure Machine Learning (AML) workspace.

Usage:
    python evaluate_experiments.py [options]

Options:
-r, --run-id <run_id>          The run id to run evaluations against.
-m, --metadata-paths <paths>   A list of metadata paths to evaluate. Paths
                                are relative from the run_outputs directory.
-u, --upload-to-aml            Providing this flag will upload to the AML workspace.

Example:
    python evaluate_experiments.py -r <run-id> -u
    python evaluate_experiments.py \
        -m run_outputs/path/to/metadata1.json run_outputs/path/to/metadata2.json -u

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

    from orchestrator.aml import AMLWorkspace
    from orchestrator.config import Config
    from orchestrator.evaluate import evaluate_experiment_results_by_run_id, evaluate_experiment_results_from_metadata

    logging.basicConfig()
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.INFO)

    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-r",
        "--run-id",
        required=False,
        help="The run ID to perform evaluations on.",
    )
    parser.add_argument(
        "-m",
        "--metadata-paths",
        nargs="*",
        required=False,
        help="A list of metadata paths to evaluate. Paths are relative from the \
            run_outputs directory",
    )
    parser.add_argument(
        "-u",
        "--upload-to-aml",
        action="store_true",
        required=False,
        help="Providing this flag will upload to the AML workspace",
    )

    args = parser.parse_args()

    if args.metadata_paths is not None and args.run_id is not None:
        raise ValueError("Please provide either a --run-id or --metadata_paths")

    aml_workspace = None
    if args.upload_to_aml:
        aml_workspace = AMLWorkspace(
            os.getenv("SUBSCRIPTION_ID"),
            os.getenv("RESOURCE_GROUP"),
            os.getenv("WORKSPACE_NAME"),
        )

    metatdata_paths = None
    if args.metadata_paths is not None:
        metatdata_paths = []
        for p in args.metadata_paths:
            metatdata_paths.append(Config.run_outputs_dir.joinpath(p))

        output = evaluate_experiment_results_from_metadata(
            metadata_paths=metatdata_paths,
            aml_workspace=aml_workspace,
            write_to_file=True,
        )

    elif args.run_id is not None:
        output = evaluate_experiment_results_by_run_id(
            run_id=args.run_id,
            aml_workspace=aml_workspace,
            write_to_file=True,
        )
    else:
        raise ValueError("Please provide either a --run-id or --metadata_paths")

    for r in output.results:
        logger.info(r)

    logger.info(f"Eval Run ID: {output.eval_run_id}")
