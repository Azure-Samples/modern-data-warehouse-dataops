import json
import logging
import os
from dataclasses import asdict
from pathlib import Path
from typing import Any, Optional

from common.analyze_submissions import analyze_submission_folder
from common.azure_storage_utils import get_blob_service_client
from common.chunking import DocContentChunker, get_encoded_tokens
from common.citation_db import commit_forms_docs_citations_to_db
from common.citation_generator_utils import Citation, validate_retrieved_citations
from common.llm.azure_openai import AzureOpenAILLM
from common.llm.credentials import OAICredentials
from common.prompt_templates import load_template

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

PROMPT_TEMPLATES_DIR = Path(__file__).parent.joinpath("prompt_templates")


class LLMCitationGenerator:
    def __init__(
        self,
        question: str,
        question_prompt_file: str = "question_prompt.txt",
        system_prompt_file: str = "system_prompt.txt",
        run_id: Optional[str] = None,
        variant_name: Optional[str] = None,
        db_question_id: Optional[int] = None,
        token_encoding_name: str = "o200k_base",  # gpt-4o
        completion_token_limit: int = 3000,
        overlap: int = 100,
        **kwargs: Any,
    ) -> None:
        self.question = question
        # Prompts
        system_prompt_template = load_template(PROMPT_TEMPLATES_DIR.joinpath(system_prompt_file))
        self.system_prompt = system_prompt_template.render(question=question)

        self.user_prompt_template = load_template(PROMPT_TEMPLATES_DIR.joinpath(question_prompt_file))
        # get token count without context
        user_prompt_without_context = self.user_prompt_template.render(question=question)
        prompt_tokens_without_context = get_encoded_tokens(
            text=self.system_prompt + user_prompt_without_context, encoding_name=token_encoding_name
        )
        max_context_tokens = completion_token_limit - len(prompt_tokens_without_context)
        if max_context_tokens <= 0:
            raise ValueError(
                f"Prompt is too long. Please reduce the prompt length to fit within {completion_token_limit} tokens."
            )
        self.chunker = DocContentChunker(
            max_tokens=max_context_tokens, encoding_name=token_encoding_name, overlap=overlap
        )

        self.db_question_id = db_question_id
        self.db_form_suffix = f"{variant_name}_{run_id}"

        self.write_to_db = os.getenv("CITATION_DB_ENABLED", "False").lower() == "true"
        if self.write_to_db:
            self.db_creator = "llm-citation-generator"
            # ensure we have required arguments for citation db
            self.db_conn_str = os.environ["CITATION_DB_CONNECTION_STRING"]
            if self.db_question_id is None:
                raise KeyError("'question_id' is a required argument when Citation DB is enabled.")

        self.blob_account_url = os.environ["AZURE_STORAGE_ACCOUNT_URL"]
        self.llm_creds = OAICredentials.from_env()

    def __call__(self, submission_folder: str, **kwargs: Any) -> dict:
        output: dict = {}
        llm = AzureOpenAILLM(creds=self.llm_creds)
        blob_service_client = get_blob_service_client(account_url=self.blob_account_url)
        docs = analyze_submission_folder(
            blob_service_client=blob_service_client,
            folder_name=submission_folder,
        )

        if len(docs) == 0:
            raise ValueError(f"No documents found for submission {submission_folder}")

        logger.debug(f"Found {len(docs)} documents for submission {submission_folder}")

        chunked_docs = self.chunker.chunk(docs=docs)

        citations = []
        docs_len = len(chunked_docs)
        for doc_idx, cd in enumerate(chunked_docs):
            logger.debug(f"Chunked document: {cd.doc.document_name}")

            chunk_len = len(cd.chunks)
            for chunk_idx, chunk in enumerate(cd.chunks):
                logger.debug(f"Sending chunk {chunk_idx+1} of {chunk_len} for doc {doc_idx+1} of {docs_len} to LLM")

                user_prompt = self.user_prompt_template.render(context=chunk, question=self.question)
                # ask llm with context
                msgs = [
                    llm.system_message(content=self.system_prompt),
                    llm.user_message(content=user_prompt),
                ]
                completion = llm.client.complete(
                    messages=msgs,
                    response_format=llm.json_response_format(),
                    seed=42,
                    temperature=0,
                )
                citation_str = completion.choices[0].message.content

                # citation_results = []
                if citation_str is not None:
                    citations_to_validate = json.loads(citation_str)
                    citations = validate_retrieved_citations(
                        retrieved_citations=citations_to_validate.get("citations", []),
                        docs=docs,
                    )
                    citations.extend(citations)

        output["citations"] = [asdict(c) for c in citations]

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
