import json
import logging
import os
from dataclasses import asdict
from pathlib import Path
from typing import Any, Optional

from azure.ai.inference import ChatCompletionsClient
from azure.ai.inference.models import SystemMessage, UserMessage
from azure.core.credentials import AzureKeyCredential
from common.analyze_submissions import analyze_submission_folder
from common.azure_storage_utils import get_blob_service_client
from common.citation_db import commit_to_db
from common.citation_generator_utils import Citation, validate_retrieved_citations
from common.file_utils import read_file
from jinja2 import Template

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

PROMPT_TEMPLATES_DIR = Path(__file__).parent.joinpath("prompt_templates")

SUBMISSION_CONTAINER = "data"
RESULTS_CONTAINER = "di-results"


class LLMCitationGenerator:
    def __init__(
        self,
        run_id: Optional[str] = None,
        system_prompt_file: str = "system_prompt.txt",
        question_prompt_file: str = "question_prompt.txt",
        **kwargs: Any,
    ) -> None:
        # DB
        self.write_to_db = os.getenv("CITATION_DB_ENABLED", "False").lower() == "true"
        self.run_id = run_id
        self.db_creator = "llm-citation-generator"
        self.db_conn_str = os.environ.get("CITATION_DB_CONNECTION_STRING")
        if self.write_to_db:
            if self.db_conn_str is None:
                raise ValueError(
                    "CITATION_DB_CONNECTION_STRING env variable is required when CITATION_DB_ENABLED is True"
                )

        # Blob
        self.blob_service_client = get_blob_service_client(account_url=os.environ["AZURE_STORAGE_ACCOUNT_URL"])

        # LLM
        self.llm_client = ChatCompletionsClient(
            endpoint=os.environ["AZURE_OPENAI_ENDPOINT"],
            credential=AzureKeyCredential(os.environ["AZURE_OPENAI_KEY"]),
            api_version=os.environ["AZURE_OPENAI_API_VERSION"],
        )

        # Prompts
        sys_prompt_txt = read_file(PROMPT_TEMPLATES_DIR.joinpath(system_prompt_file))
        self.system_prompt = Template(sys_prompt_txt).render()

        question_prompt_txt = read_file(PROMPT_TEMPLATES_DIR.joinpath(question_prompt_file))
        self.question_prompt_template = Template(question_prompt_txt)

    def __call__(self, submission_folder: str, question: str, question_id: Optional[int] = None, **kwargs: Any) -> dict:
        # Get DI results for submission
        docs = analyze_submission_folder(
            blob_service_client=self.blob_service_client,
            folder_name=submission_folder,
            submission_container=SUBMISSION_CONTAINER,
            results_container=RESULTS_CONTAINER,
        )

        # Prepare question prompt
        doc_text_list = []
        for d in docs:
            content = d.di_result["content"]
            doc_text_list.append(f"{content}\n")
        document_text = "".join(doc_text_list)

        question_prompt = self.question_prompt_template.render(documents=document_text, question=question)

        # Generate citations
        msgs = [
            SystemMessage(content=self.system_prompt),
            UserMessage(content=question_prompt),
        ]
        completion = self.llm_client.complete(
            messages=msgs,
            response_format="json_object",
            seed=44,
            temperature=0,
        )
        citation_str = completion.choices[0].message.content

        # Validate citations
        citation_results = []
        if citation_str is not None:
            citations_to_validate = json.loads(citation_str)
            citations = validate_retrieved_citations(
                retrieved_citations=citations_to_validate.get("citations", []),
                docs=docs,
            )

            for c in citations:
                citation_results.append(asdict(c))

        output: dict = {"citations": citation_results}

        valid_citations = [c for c in citations if isinstance(c, Citation)]

        # Write to DB
        if self.write_to_db:
            if question_id is None:
                raise ValueError("question_id is required when CITATION_DB_ENABLED is True")

            form_name = f"{submission_folder}_{self.run_id}" if self.run_id is not None else submission_folder
            logger.info(f"Adding {len(valid_citations)} citations to form {form_name}")

            form_id = commit_to_db(
                conn_str=self.db_conn_str,
                form_name=form_name,
                question_id=question_id,
                docs=docs,
                creator=self.db_creator,
                citations=valid_citations,
            )
            output["form_id"] = form_id

        return output


if __name__ == "__main__":
    from dotenv import load_dotenv

    load_dotenv()

    generator = LLMCitationGenerator()
    output = generator(
        submission_folder="test-submission-2",
        question="What was the company’s revenue for the third quarter of Fiscal Year 2024?",
    )
    for c in output["citations"]:
        print(f"Document: {c.get('document_name')}")
        print(f"Excerpt: {c.get('excerpt')}")
        print(f"Explanation: {c.get('explanation')}")
        print(f"Status: {c.get('status')}")
