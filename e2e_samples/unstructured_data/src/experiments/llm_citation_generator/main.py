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
from common.chunking import AnalyzedDocChunker, get_encoded_tokens
from common.citation import Citation, InvalidCitation, ValidCitation
from common.citation_db import commit_to_db
from common.citation_generator_utils import validate_citation
from common.file_utils import read_file
from common.llm.credentials import OAICredentials
from common.prompt_templates import load_template
from jinja2 import Template

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

PROMPT_TEMPLATES_DIR = Path(__file__).parent.joinpath("prompt_templates")


class LLMCitationGenerator:
    def __init__(
        self,
        question: str,
        run_id: Optional[str] = None,
        system_prompt_file: str = "system_prompt.txt",
        user_prompt_file: str = "user_prompt.txt",
        submission_container: str = "msft-quarterly-earnings",
        results_container: str = "msft-quarterly-earnings-di-results",
        variant_name: Optional[str] = None,
        db_question_id: Optional[int] = None,
        token_encoding_name: str = "o200k_base",  # gpt-4o
        max_tokens: int = 3000,
        overlap: int = 100,
        **kwargs: Any,
    ) -> None:
        # DB
        self.write_to_db = os.getenv("CITATION_DB_ENABLED", "False").lower() == "true"
        self.run_id = run_id
        self.db_creator = "llm-citation-generator"
        self.db_conn_str = os.environ.get("CITATION_DB_CONNECTION_STRING")
        if self.write_to_db and self.db_conn_str is None:
            raise ValueError("CITATION_DB_CONNECTION_STRING env variable is required when CITATION_DB_ENABLED is True")

        # Blob
        self.blob_service_client = get_blob_service_client(account_url=os.environ["AZURE_STORAGE_ACCOUNT_URL"])
        self.submission_container = submission_container
        self.results_container = results_container

        # LLM
        self.llm_client = ChatCompletionsClient(
            endpoint=os.environ["AZURE_OPENAI_ENDPOINT"],
            credential=AzureKeyCredential(os.environ["AZURE_OPENAI_KEY"]),
            api_version=os.environ["AZURE_OPENAI_API_VERSION"],
        )

        # Prompts
        sys_prompt_txt = read_file(PROMPT_TEMPLATES_DIR.joinpath(system_prompt_file))
        self.system_prompt = Template(sys_prompt_txt).render()

        question_prompt_txt = read_file(PROMPT_TEMPLATES_DIR.joinpath(user_prompt_file))
        self.question_prompt_template = Template(question_prompt_txt)

        self.question = question
        # Prompts
        system_prompt_template = load_template(PROMPT_TEMPLATES_DIR.joinpath(system_prompt_file))
        self.system_prompt = system_prompt_template.render(question=question)

        self.user_prompt_template = load_template(PROMPT_TEMPLATES_DIR.joinpath(user_prompt_file))
        # get token count without context to calculate max context tokens
        user_prompt_without_context = self.user_prompt_template.render(question=question)
        prompt_tokens_without_context = get_encoded_tokens(
            text=self.system_prompt + user_prompt_without_context, encoding_name=token_encoding_name
        )
        max_context_tokens = max_tokens - len(prompt_tokens_without_context)
        if max_context_tokens <= 0:
            raise ValueError(f"Prompt is too long. Please reduce the prompt length to fit within {max_tokens} tokens.")
        elif max_context_tokens < overlap:
            raise ValueError(
                f"Max context tokens {max_context_tokens} must be greater than overlap {overlap}.\
                    Please reduce overlap or reduce the prompt length."
            )
        self.chunker = AnalyzedDocChunker(
            max_tokens=max_context_tokens,
            encoding_name=token_encoding_name,
            overlap=overlap,
        )

        # Blob
        self.blob_service_client = get_blob_service_client(account_url=os.environ["AZURE_STORAGE_ACCOUNT_URL"])
        self.submission_container = submission_container
        self.results_container = results_container

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

    def __call__(self, submission_folder: str, question: str, question_id: Optional[int] = None, **kwargs: Any) -> dict:
        docs = analyze_submission_folder(
            blob_service_client=self.blob_service_client,
            folder_name=submission_folder,
            submission_container=self.submission_container,
            results_container=self.results_container,
        )

        if len(docs) == 0:
            raise ValueError(f"No documents found for submission {submission_folder}")

        logger.debug(f"Found {len(docs)} documents for submission {submission_folder}")

        chunked_docs = self.chunker.chunk_by_token(docs=docs)

        citations: list[InvalidCitation | ValidCitation] = []
        docs_len = len(chunked_docs)
        for doc_idx, cd in enumerate(chunked_docs):
            logger.debug(f"Chunked document: {cd.document_name}")

            chunk_len = len(cd.chunks)
            for chunk_idx, doc_chunk in enumerate(cd.chunks):
                logger.debug(f"Sending chunk {chunk_idx+1} of {chunk_len} for doc {doc_idx+1} of {docs_len} to LLM")
                question_prompt = self.question_prompt_template.render(documents=doc_chunk, question=question)
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

                citation_str = completion.choices[0].message.content

                # citation_results = []
                if citation_str is not None:
                    loaded_citations = json.loads(citation_str)
                    citations_to_validate: list = loaded_citations.get("citations", [])
                    for c in citations_to_validate:
                        if isinstance(c, dict):
                            citation = Citation(
                                excerpt=c.get("excerpt"),
                                document_name=cd.document_name,
                                explanation=c.get("explanation"),
                                raw=citation_str,
                            )

                            validated_citation = validate_citation(citation=citation, chunk=doc_chunk)
                            citations.append(validated_citation)
                        else:
                            citations.append(
                                InvalidCitation(
                                    document_name=cd.document_name,
                                    raw=citation_str,
                                    error="Invalid citation format",
                                )
                            )
        output: dict = {"citations": [asdict(c) for c in citations]}

        # Write to DB
        if self.write_to_db:
            valid_citations = [c for c in citations if isinstance(c, ValidCitation)]
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

    generator = LLMCitationGenerator(question="")
    output = generator(
        submission_folder="test-submission-2",
        question="What was the company’s revenue for the third quarter of Fiscal Year 2024?",
    )
    for c in output["citations"]:
        print(f"Document: {c.get('document_name')}")
        print(f"Excerpt: {c.get('excerpt')}")
        print(f"Explanation: {c.get('explanation')}")
        print(f"Status: {c.get('status')}")
