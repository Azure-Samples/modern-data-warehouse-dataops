
import re
import requests
from delta.tables import DeltaTable


def store_unit_test_results(unit_tests_results: object) -> None:
    ansi_escape = re.compile(r"\x1b\[[0-9;]*m")
    cleaned_text = ansi_escape.sub(
        "", " ".join(unit_tests_results.stdout.split("\n")[-3:])
    )
    cleaned_text = cleaned_text.replace("=", "")
    errors = re.findall(r"(\d+)\s+error", cleaned_text)
    num_errors = int(errors[0]) if errors else 0
    passes = re.findall(r"(\d+)\s+passed", cleaned_text)
    num_passes = int(passes[0]) if passes else 0
    fails = re.findall(r"(\d+)\s+failed", cleaned_text)
    num_fails = int(fails[0]) if fails else 0
    runtime = re.findall(r"\s+in\s+(.+)\s+", cleaned_text)
    runtime = runtime[0].strip() if runtime else "N/A"

    # TO DO: Store these results somewhere
    # Details to include: workspace details, deployment identifierers release name, configs/params used, user information, test statuses etc
    print(f"{num_errors =}, {num_passes =}, {num_fails =}, {runtime =}")


# Getting workspace id - using Fabric REST APIS
def make_fabric_api_call(token: str, url: str, call_type: str, payload: str) -> object:
    headers = {"Authorization": f"Bearer {token}"}
    try:
        if call_type == "get":
            response = requests.get(url, data=payload, headers=headers)
        elif call_type == "put":
            response = requests.put(url, data=payload, headers=headers)
        else:
            raise ValueError(
                f"Invalid {call_type = }. It must be either 'get' or 'put'."
            )
    except Exception as e:
        logger.error(f"Failed with error {e}")
        raise
    else:
        ## print(f"{response.status_code = }\n\n{response.content = }\n\n{response.headers = }\n\n{response.json() = }\n\n{response.text =}")
        return response


def verify_onelake_connection():
    cur_span = trace.get_current_span()

    # Check onelake existence - otherwise abort notebook execution
    error_message = f"Specfied lakehouse table path {onelake_table_path} doesn't exist. Ensure onelake={onelake_name}, workspace={workspace_name} and lakehouse={lakehouse_name} exist."
    try:
        if not (notebookutils.fs.exists(onelake_table_path)):
            raise ValueError(
                "Encountered error while checking for Lakehouse table path specified."
            )
    except Exception as e:
        logger.exception(f"Error message: {e}")
        cur_span.record_exception(e)
        cur_span.set_status(StatusCode.ERROR, "Onelake connection verification failed.")
        # no further execution but Session is still active
        notebookutils.notebook.exit(error_message)
    else:
        cur_span.set_status(StatusCode.OK)
        logger.info(
            f"Target table path: {onelake_table_path} is valid and exists.\nListing source data contents to check connectivity\n{notebookutils.fs.ls(wasbs_path)}"
        )


def identify_table_load_mode(table_name: str, span_obj: object) -> bool:

    # Preferred option - Assuming default lakehouse is not set, checking based on the delta path
    load_mode = (
        "append"
        if DeltaTable.isDeltaTable(spark, f"{onelake_table_path}/{table_name}")
        else "overwrite"
    )

    # getting span object as an argument - as opposed to using trace.get_current_span() to find current span.
    span_obj.set_attribute("load_mode", load_mode)

    return load_mode


def delete_delta_table(table_name: str) -> bool:

    delta_table_path = f"{onelake_table_path}/{table_name}"

    if notebookutils.fs.exists(delta_table_path):
        logger.info(
            f"Attempting to delete existing delta table with {delta_table_path = }...."
        )

        try:
            notebookutils.fs.rm(dir=delta_table_path, recurse=True)
        except Exception as e:
            logger.error(f"Deletion failed with the error:\n===={e}\n=====")
            raise
        else:
            logger.info(f"Deleted existing delta table: {table_name}.")
    else:
        logger.info(f"The specified delta table doesn't exist. No need for deletion.")