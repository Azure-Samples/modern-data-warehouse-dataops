import json
from dataclasses import asdict
from pathlib import Path
from typing import Any, Optional

from azure.ai.inference import ChatCompletionsClient
from azure.ai.inference.models import SystemMessage, UserMessage
from azure.core.credentials import AzureKeyCredential
from azure.core.exceptions import ResourceNotFoundError
from common.analyze_submissions import analyze_submission_folder
from common.azure_storage_utils import get_blob_service_client
from common.chunking import AnalyzedDocChunker, get_chunk_max_tokens
from common.citation import Citation, InvalidCitation, ValidCitation
from common.citation_db import CitationDB, commit_to_db
from common.citation_generator_utils import validate_citation
from common.config import Config
from common.di_utils import get_doc_analysis_client
from common.logging_utils import get_logger
from common.oai_credentials import OAICredentials
from common.prompt_templates import load_template

logger = get_logger(__name__)

PROMPT_TEMPLATES_DIR = Path(__file__).parent.joinpath("prompt_templates")


class LLMCitationGenerator:
    def __init__(
        self,
        question: str,
        db_question_id: Optional[int] = None,
        system_prompt_file: str = "system_prompt.txt",
        user_prompt_file: str = "user_prompt.txt",
        submission_container: str = "msft-quarterly-earnings",
        results_container: str = "msft-quarterly-earnings-di-results",
        token_encoding_name: str = "o200k_base",  # gpt-4o
        max_tokens: int = 4000,
        overlap: int = 100,
        run_id: Optional[str] = None,
        **kwargs: Any,
    ) -> None:
        config = Config.from_env()
        # DB
        self.citation_db = None
        if config.citation_db_enabled:
            self.citation_db = CitationDB(
                conn_str=config.citation_db_conn_str, question_id=db_question_id, run_id=run_id
            )

        # Blob
        if config.azure_storage_account_url is None:
            raise ValueError("AZURE_STORAGE_ACCOUNT_URL is required")
        self.blob_service_client = get_blob_service_client(account_url=config.azure_storage_account_url)
        self.submission_container = submission_container
        self.results_container = results_container

        # LLM
        llm_creds = OAICredentials.from_config(config)
        self.llm_client = ChatCompletionsClient(
            endpoint=llm_creds.deployment_endpoint,
            credential=AzureKeyCredential(llm_creds.api_key),
            api_version=llm_creds.api_version,
        )

        # Prompts
        self.question = question
        system_prompt_template = load_template(PROMPT_TEMPLATES_DIR.joinpath(system_prompt_file))
        self.system_prompt = system_prompt_template.render(question=question)

        self.user_prompt_template = load_template(PROMPT_TEMPLATES_DIR.joinpath(user_prompt_file))
        user_prompt_without_context = self.user_prompt_template.render(question=question)

        # Chunking
        chunk_max_tokens = get_chunk_max_tokens(
            self.system_prompt + user_prompt_without_context, token_encoding_name, max_tokens, overlap
        )
        self.chunker = AnalyzedDocChunker(
            max_tokens=chunk_max_tokens,
            encoding_name=token_encoding_name,
            overlap=overlap,
        )

        # DI
        if config.di_endpoint is None:
            raise ValueError("DOCUMENT_INTELLIGENCE_ENDPOINT is required")
        if config.di_key is None:
            raise ValueError("DOCUMENT_INTELLIGENCE_KEY is required")
        self.di_client = get_doc_analysis_client(endpoint=config.di_endpoint, api_key=config.di_key)
        self.override_di_results = config.override_di_results

    def __call__(self, submission_folder: str, **kwargs: Any) -> dict:
        docs = analyze_submission_folder(
            blob_service_client=self.blob_service_client,
            folder_name=submission_folder,
            di_client=self.di_client,
            submission_container=self.submission_container,
            results_container=self.results_container,
            override_di=self.override_di_results,
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
                if chunk_idx > 2:
                    break
                logger.debug(f"Sending chunk {chunk_idx+1} of {chunk_len} for doc {doc_idx+1} of {docs_len} to LLM")
                question_prompt = self.user_prompt_template.render(context=doc_chunk, question=self.question)
                msgs = [
                    SystemMessage(content=self.system_prompt),
                    UserMessage(content=question_prompt),
                ]
                try:
                    completion = self.llm_client.complete(
                        messages=msgs,
                        response_format="json_object",
                        seed=44,
                        temperature=0,
                    )
                except ResourceNotFoundError as e:
                    logger.error(
                        f"Azure ChatCompletionsClient not found. Please ensure the correct env variables are set {e}"
                    )
                    raise e
                citation_str = completion.choices[0].message.content

                if citation_str is not None:
                    loaded_citations = json.loads(citation_str)
                    citations_to_validate: list = loaded_citations.get("citations", [])
                    logger.debug(f"Validating {len(citations_to_validate)} citations")
                    for c in citations_to_validate:
                        if isinstance(c, dict):
                            excerpt = c.get("excerpt")
                            if excerpt is None:
                                citations.append(
                                    InvalidCitation(
                                        document_name=cd.document_name,
                                        raw=c.get("raw"),
                                        error="Missing 'excerpt' key",
                                    )
                                )
                                continue
                            citation = Citation(
                                excerpt=excerpt,
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
        if self.citation_db is not None:
            valid_citations = [c for c in citations if isinstance(c, ValidCitation)]
            form_name = f"{submission_folder}{self.citation_db.form_suffix}"
            logger.info(f"Adding {len(valid_citations)} citations to form {form_name}")

            form_id = commit_to_db(
                conn_str=self.citation_db.conn_string,
                form_name=form_name,
                question_id=self.citation_db.question_id,
                docs=docs,
                creator=self.citation_db.creator,
                citations=valid_citations,
            )
            output["form_id"] = form_id

        return output


if __name__ == "__main__":
    from dotenv import load_dotenv

    load_dotenv()

    generator = LLMCitationGenerator(question="What was the company’s revenue for the latest Fiscal Year?")
    output = generator(
        submission_folder="F24Q3",
    )
    for c in output["citations"]:
        print(f"Document: {c.get('document_name')}")
        print(f"Excerpt: {c.get('excerpt')}")
        print(f"Explanation: {c.get('explanation')}")
        print(f"Status: {c.get('status')}")
