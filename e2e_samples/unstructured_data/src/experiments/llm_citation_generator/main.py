import json
import logging
import os
from dataclasses import asdict
from pathlib import Path
from typing import Any, Optional

from common.analyze_submissions import analyze_submission_folder
from common.azure_storage_utils import get_blob_service_client
from common.citation_db import commit_forms_docs_citations_to_db
from common.citation_generator_utils import Citation, validate_retrieved_citations
from common.llm.azure_openai import AzureOpenAILLM
from common.llm.credentials import OAICredentials
from common.prompt_templates import get_rendered_prompt_template

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

BASE_DIR = Path(__file__).parent
PROMPT_TEMPLATES_DIR = str(BASE_DIR.joinpath("prompt_templates"))


class LLMCitationGenerator:
    def __init__(
        self,
        prompt_templates: dict,
        run_id: str,
        variant_name: str,
        db_question_id: Optional[int] = None,
        **kwargs: Any,
    ) -> None:
        self.common_prompt_variables = prompt_templates.get("variables", {})
        self.system_prompt_template = prompt_templates.get("system", {})
        self.user_prompt_template = prompt_templates.get("user", {})
        self.db_question_id = db_question_id
        self.db_form_suffix = f"{variant_name}_{run_id}"

        self.write_to_db = os.getenv("CITATION_DB_ENABLED", "False").lower() == "true"
        if self.write_to_db:
            self.db_creator = "llm-citation-generator"
            # ensure we have required arguments for citation db
            self.db_conn_str = os.environ["CITATION_DB_CONNECTION_STRING"]
            if self.db_question_id is None:
                raise KeyError("'db_question_id' is a required argument when Citation DB is enabled.")

        self.blob_account_url = os.environ["AZURE_STORAGE_ACCOUNT_URL"]
        self.llm_creds = OAICredentials.from_env()

    def __call__(self, submission_folder: str, **kwargs: Any) -> dict:
        llm = AzureOpenAILLM(creds=self.llm_creds)
        blob_service_client = get_blob_service_client(account_url=self.blob_account_url)
        docs = analyze_submission_folder(
            blob_service_client=blob_service_client,
            folder_name=submission_folder,
        )

        context_list = []
        for d in docs:
            content = d.di_result["content"]
            context_list.append(f"{content}\n")
        context = "".join(context_list)

        # context and common variables like the question may be in
        # either system prompt or user prompt
        # add to both. Non-common vars take precidence
        # Copy the class dicts so the updated values are not used on subsequent calls
        common_variables = self.common_prompt_variables.copy()
        common_variables["context"] = context

        system_prompt_template = self.system_prompt_template.copy()
        system_prompt_template["variables"] = common_variables | self.system_prompt_template.get("variables", {})

        user_prompt_template = self.user_prompt_template.copy()
        user_prompt_template["variables"] = common_variables | self.user_prompt_template.get("variables", {})

        system_prompt = get_rendered_prompt_template(templates_dir=PROMPT_TEMPLATES_DIR, **system_prompt_template)
        user_prompt = get_rendered_prompt_template(templates_dir=PROMPT_TEMPLATES_DIR, **user_prompt_template)

        # ask llm with context
        msgs = [
            llm.system_message(content=system_prompt),
            llm.user_message(content=user_prompt),
        ]
        completion = llm.client.complete(
            messages=msgs,
            response_format=llm.json_response_format(),
            seed=42,
            temperature=0,
        )
        citation_str = completion.choices[0].message.content

        citation_results = []
        if citation_str is not None:
            citations_to_validate = json.loads(citation_str)
            citations = validate_retrieved_citations(
                retrieved_citations=citations_to_validate.get("citations", []),
                docs=docs,
            )

            for c in citations:
                citation_results.append(asdict(c))

        output: dict[str, Any] = {"citations": citation_results}
        # # upload to db
        if self.write_to_db:
            form_name = f"{submission_folder}_{self.db_form_suffix}"
            valid_citations = [c for c in citations if isinstance(c, Citation)]
            logger.info(f"Adding {len(valid_citations)} citations to form {form_name}")
            if self.db_question_id is None:
                raise KeyError("'db_question_id' is a required argument when Citation DB is enabled.")
            form_id = commit_forms_docs_citations_to_db(
                conn_str=self.db_conn_str,
                form_name=form_name,
                question_id=self.db_question_id,
                docs=docs,
                creator=self.db_creator,
                citations=valid_citations,
            )
            output["db_form_id"] = form_id
            output["db_question_id"] = self.db_question_id

        return output


if __name__ == "__main__":
    from common.path_utils import RepoPaths
    from dotenv import load_dotenv
    from orchestrator.run_experiment import load_experiments
    from orchestrator.telemetry_utils import configure_telemetry
    from orchestrator.utils import new_run_id

    load_dotenv(override=True)
    configure_telemetry()  # local telemetry
    config_filepath = RepoPaths.experiment_config_path("llm_citation_generator")

    variants = ["questions/total-revenue/1.yaml"]
    run_id = new_run_id()
    experiments = load_experiments(
        config_filepath=config_filepath,
        variants=variants,
        run_id=run_id,
    )
    submission_folder = "josh-test"
    for experiment in experiments:
        result = experiment.run(submission_folder=submission_folder)
        print(result)
    print(f"Run ID: {run_id}")
