# Experiments and Evaluations

The unstructured data end-to-end sample contains an experiment `llm_citation_generator` which generates citations for a given question against a set of PDF documents. It uses an LLM to find the excerpts in the document that help answer the question.

An experiment can be run using the orchestrator, which is responsible for running experiments and evaluations against a JSONL data file with a set of variants.

**Experiment**: A Python class that implements `__call__` and `__init__` methods.
**Variant**: A YAML file that defines the arguments passed to the `__call__` and `__init__` methods. This also defines the evaluators that should be used when evaluating the experiment results.

## Experiments

### How to Run

#### Script

A script has been provided to run experiments from the command line and is located at `scripts/run_experiments.py`.

```text
Usage:
    - python ./scripts/run_experiments.py
    - python ./scripts/run_experiments.py -e <experiment-config-path> -v <path-from-variants-dir-1> <path-from-variants-dir-2> -i <run-id> -d <path-in-data-dir> -o <output-dir> -t <app_insights|local>
    - python ./scripts/run_experiments.py -e llm_citation_generator/config/experiment.yaml -v questions/total-revenue/1.yaml questions/earnings-per-share/1.yaml -d test-data.jsonl -o -t local

Options:
    -e, --experiment-config-path <experiment-config-path>   The directory name of the experiment. Default is "llm_citation_generator".
    -v, --variants <paths>                                  A list of variant paths. Paths are relative from the variants directory for the experiment.
    -i, --run-id <run-id>                                   The run id. Default is a timestamp: YmdHMS.
    -d, --data-path <path>                                  The path to the data file in the data directory.
    -o, --output-dir <path>                                 The output directory for the experiment results.
    -t, --telemetry <app_insights|local>                    The telemetry configuration. Can be "app_insights" or "local".
```

An experiment must have an `experiment.yaml` which defines how to load the experiment and optionally defines a set of evaluators.

#### Code

To run an experiment in Python, use the orchestrator's `run_experiments` function.

```python
from orchestrator.run_experiment import run_experiments

run_results = run_experiments(
    config_filepath="llm_citation_generator/config/experiment.yaml",
    variants=["<variant-1-path>", "<variant-2-path>"],
    run_id="123",
    data_path="<path-to-data>",
    write_to_file=True,
    is_eval_data=True,
)
results = run_results.results
run_id = run_results.run_id
```

### How to Create a New Experiment

An experiment is a Python class with `__call__` and `__init__` methods. To run an experiment with the orchestrator, it must have an experiment configuration file and at least one variant configuration file.

#### File Structure

The experiment configuration can define a custom path for the variants directory, but the default file structure for experiment files is as follows:

```text
└── experiments
  └── <experiment_name>
    ├── main.py -> the entry point to the experiment
    └──  config
      ├── experiment.yaml
      └── variants -> the variants directory, containing all variant config files
        ├── <...variant-config-files>.yaml
```

> Note: For the `llm_citation_generator`, the variants directory is defined as `questions`.

#### Experiment Classes

An experiment is a Python class that has defined `__call__` and `__init__` methods.

Requirements:

- `__init__` method must accept `**kwargs` or `run_id` and `variant_name` because the orchestrator passes these values as keyword arguments to each experiment.
- `__call__` method must accept `**kwargs` or the top-level values listed in each line of the data file that is passed to the orchestrator.

Example:

```python
class Experiment:
    def __init__(self, question: str, run_id: str, **kwargs):
        self.question = question
        self.run_id = run_id

    def __call__(self, submission_folder: str, **kwargs):
        ...
```

This experiment would expect a data file that looks like the following:

```json
{"submission_folder": "path/to/submission-1"}
{"submission_folder": "path/to/submission-2"}
{"submission_folder": "path/to/submission-3"}
```

The experiment would also expect a variant that defines `init_args.question` in the YAML definition. The class is initialized once for each variant.

For each data line, the experiment's call method would be invoked using the data from that line. To support evaluations, the data file can also contain additional evaluation data in each line. For this reason, a `__call__` method should accept `**kwargs`, so they can be ignored if included in the data file. All input data from this file is included in the experiment results output for each data line in a flat list.

Example data file with truth:

```json
{"submission_folder": "path/to/submission-1", "truth": {"total-revenue": "100", "earnings-per-share": "1.11"}}
{"submission_folder": "path/to/submission-2", "truth": {"total-revenue": "150", "earnings-per-share": "2.22"}}
{"submission_folder": "path/to/submission-3", "truth": {"total-revenue": "125", "earnings-per-share": "3.33"}}
```

Example output of the experiment results:

```json
{"inputs.submission_folder": "path/to/submission-1", "inputs.truth.total-revenue": "100", "inputs.truth.earnings-per-share": "1.11", "citations": ["citation1", "citation2"]}
{"submission_folder": "path/to/submission-2", "truth": {"inputs.truth.total-revenue": "150", "inputs.truth.earnings-per-share": "2.22"}, "citations": ["citation1"]}
{"submission_folder": "path/to/submission-3", "truth": {"inputs.truth.total-revenue": "125", "inputs.truth.earnings-per-share": "3.33"}, "citations": ["citation1", "citation2", "citation3"]}
```

#### Experiment Configuration

Each experiment must have an experiment configuration file. This enables the orchestrator to load the experiment. This defines the module, class, and name, which enables dynamically loading the experiment. Evaluators can be listed in this file for variants to reference when running evaluations.

Example `experiment.yaml`:

```yaml
# experiment.yaml
name: llm-citation-generator                     # name of the experiment
module: experiments.llm_citation_generator.main  # module to load
class_name: LLMCitationGenerator                 # class name of the experiment
variants_dir:                                    # the relative path to the variants directory, by default it is ./variants
evaluators:                                      # evaluators - dict of [name, config]
  fuzzy_match:                                   # evaluator name
    module: evaluators.fuzzy_match               # evaluator module to load
    class_name: FuzzyMatchEvaluator              # evaluator class name
    evaluator_config:                            # evaluator config
      column_mapping:                            # the column mapping of the data file to the evaluator __call__ method parameters
        response: ${data.citations}
                                                 # truth is omitted in the column mapping here because each variant defines the truth mapping
```

#### Variants

An experiment must have at least one variant defined to run with the orchestrator. Variants serve as a way to test variations of an experiment. They define the `init_args` and `call_args` that are passed into the experiment `__init__` and `__call__` methods. In addition, it defines the name and version. Optionally, this can also define evaluators needed for evaluation, additional config through parent variants, and an output container.

> Note: A name and version must be unique for each variant in an experiment run.

Example variant configuration:

```yaml
name: variant-name                  # The name of the variant
version:                            # The version of the variant.
output_container:                   # An optional key to specify the directory for which this variant output should be written
                                    # the final output will be run_outputs/<exp-name>/<output_container>/...
parent_variants:                    # A list of relative paths to additional config. This can be used to eliminate duplicate code when multiple variants share configuration.
    - "parent-1.yaml"
init_args:                          # Initialization arguments for the experiment
  init_arg_1: some-value
call_args:                          # __call__ arguments for the experiment. These will be combined with the JSONL data lines values
  call_arg_1: some-value
evaluation:                         # Defines the evaluation configuration for evaluation runs
  init_args:                        # Common init_args that are passed to ALL defined evaluators. Each evaluator can also define their own init_args or override what is listed here.
    eval_example_param_1: some-value

  evaluators:                       # Evaluator configuration: dict[evaluator name, EvaluatorLoadConfig]
    fuzzy_match:                    # The name of the evaluator, this is a reference to the evaluators listed in the experiment.yaml configuration file.
                                    # Values can be set or overridden here if the variant needs different values than what is provided in experiment.yaml.
        evaluator_config:
            column_mapping:
                truth: ${data.truth.some-value}
                                    # The values listed here will be merged with the values in experiment.yaml with these values taking precedence

  tags:                             # Any tags that should be included when uploading evaluation results to AML
    tag_1_name: tag-1-value
```

##### Parent Variants

In some cases, it is preferable to define common variant parameters in a reusable configuration file that can be referenced.

For example, in the Citation Generator, there are many questions that use common prompts and have a common db_question_id. The common configuration can be referenced by providing `parent_variants`.

When variant configuration files are merged and duplicate keys are found:

- If both configs have a dictionary at the same key, those dictionaries are merged recursively.
- If the same key has non-dictionary values in both dictionaries, the value from the second dictionary will overwrite the value from the first dictionary.
- In all other cases, the value of the variant config with precedence will be used.

## Evaluation

Evaluations can be performed on experiment results and optionally uploaded to an Azure Machine Learning Workspace.

### Run an Evaluation

Evaluations can be performed by providing a run ID or list of metadata files from an experiment run. When the orchestrator runs an experiment, a metadata file is generated. The orchestrator will traverse the `run_outputs` directory and load every `metadata.json` file under a directory with the name of the run ID. The metadata file contains the information needed to run an evaluation.

The results are written to the metadata's directory with a name of `<eval-run-id>_eval_results.json`. In addition, the results can be uploaded to a provided AML workspace.

The evaluation configuration is loaded from the variant and experiment configuration files.

#### Script

A script has been provided to run evaluations from the command line and is located at `scripts/evaluate_experiments.py`.

```text
Usage:
    python evaluate_experiments.py [options]

Options:
-r, --run-id <run_id>          The run id to run evaluations against.
-m, --metadata-paths <paths>   A list of metadata paths to evaluate. Paths are relative from the run_outputs directory.
-u, --upload-to-aml            Providing this flag will upload to the AML workspace. `SUBSCRIPTION_ID`, `RESOURCE_GROUP`, and `WORKSPACE_NAME` environment variables must be set in `.env`.

Example:
    python evaluate_experiments.py -r <run-id> -u
```

If the run_id is provided, the `run_outputs` directory will be traversed and load every `metadata.json` file under a directory with the name of the run ID. Alternatively, a list of metadata files can be provided. The paths are relative to the run_outputs directory. Either run_id or metadata paths must be provided but not both.

#### Code

To run an evaluation on experiment results in Python, use the orchestrator's `evaluate_experiment_results_from_metadata` or `evaluate_experiment_results_by_run_id` functions.

```python
from orchestrator.evaluate import evaluate_experiment_results

output = evaluate_experiment_results_by_run_id(
    run_id=run_id,
    aml_workspace=aml_workspace,
    write_to_file=True
)
results = output.results
eval_run_id = output.eval_run_id
```

### Metadata File

The metadata file is a JSON file that contains all the information needed to perform an evaluation on an experiment result. It contains:

- `run_id`: the run id (This is additional data and not a requirement for evaluations)
- `experiment_config_path`: The relative path to the experiment config file from the experiment directory. The experiments directory can be set with the environment variable `EXPERIMENTS_DIR`.
- `variant_config_path`: The relative path to the variant config file from the variants directory. The variant directory can be set in the experiment config and has a default of `./variants`.
- `exp_results_path`: The relative path to the experiment results file (This is additional data and not a requirement for evaluations).
- `eval_data_path`: The relative path to the file that should be used for evaluations. It is possible that this value and the `exp_results_path` are identical.

The variant and experiment configuration files should contain the evaluation configuration.

### Add a New Evaluator

1. Create a new Python class in a new Python file for your metric under `./src/evaluators`. The class should contain an `__init__` method and a `__call__` method. The `__call__` should implement the metric logic. There are 2 options here:
    - You can select from a standard catalog of evaluators that Azure provides. See here for a list of all the [standard evaluators available](https://learn.microsoft.com/en-us/python/api/azure-ai-evaluation/azure.ai.evaluation?view=azure-python-preview#classes). Check out [fuzzy_match.py](../src/evaluators/fuzzy_match.py) to see an example.
    - Or implement your own custom logic. Check out [exact_numeric_match.py](../src/evaluators/exact_numeric_match.py) to see an example.

2. Register the new metric to the experiments and configure it to the questions for which you want to apply this metric. Navigate to [experiment.yaml](../src/experiments/llm_citation_generator/config/experiment.yaml) file and add the following lines under `evaluators`:

```yaml
  <evaluator_name>:
    module: evaluators.<evaluator_file_name>
    class_name: <evaluator_class_name>
    evaluator_config:
      column_mapping:
        response: ${data.citations}
        truth: ${data.truth}
```

Navigate to the questions (`../src/experiments/llm_citation_generator/config/questions/`) folder in experiments and go to the config file under a specific question's folder. Add your metric file name under evaluators.

```yaml
evaluation:
  evaluators:
    <evaluator_name>:
```

You are all good to go. Remember to re-run your experiments to make sure the metadata for evaluators is updated before running the evaluation.

#### Evaluation Configuration

Evaluations can be configured by providing an `evaluation` object in the variant config file.

```yaml
# variant config
evaluation:                                     # The evaluation configuration object
  init_params:                                  # any parameters to pass to ALL evaluator __init__ methods
  evaluators:                                   # The evaluators configuration object
    <evaluator_name_1>:                         # The friendly name of the evaluator
                                                # This object will be merged with the experiment config evaluators
    <evaluator_name_2>:
      module: evaluators.<evaluator_file_name>  # the variant can also specify the evaluator config directly if not contained in the experiment config.
                                                # the two configs will be merged with the variant values taking precedence
      class_name: <evaluator_class_name>
      init_params:                              # any parameters to pass to this evaluator __init__ method
                                                # values from here will merge/overwrite the top-level init_params
      evaluator_config:                         # the evaluator config used by azure.ai.evaluation evaluate function
        column_mapping:
          response: ${data.citations}
          truth: ${data.truth}
```
