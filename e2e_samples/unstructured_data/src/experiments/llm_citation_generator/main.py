import json
from dataclasses import asdict
from pathlib import Path
from typing import Any, Optional

from azure.ai.inference.models import SystemMessage, UserMessage
from azure.identity import DefaultAzureCredential
from common.analyze_submissions import analyze_submission_folder
from common.azure_storage_utils import AzureStorageConfig, get_blob_service_client
from common.chunking import AnalyzedDocChunker, get_context_max_tokens
from common.citation import Citation, InvalidCitation, ValidCitation
from common.citation_db import CitationDBConfig, commit_forms_docs_citations_to_db
from common.citation_generator_utils import validate_citation
from common.config_utils import EnvFetcher
from common.di_utils import DIConfig, get_doc_analysis_client
from common.llm import AzureOpenAIConfig, get_chat_completions_client
from common.logging import get_logger
from common.prompt_templates import load_template

logger = get_logger(__name__)

PROMPT_TEMPLATES_DIR = Path(__file__).parent.joinpath("prompt_templates")


class LLMCitationGenerator:
    def __init__(
        self,
        question: str,
        user_prompt_file: str = "user_prompt.txt",
        system_prompt_file: str = "system_prompt.txt",
        db_question_id: Optional[int] = None,
        token_encoding_name: str = "o200k_base",  # gpt-4o, see https://gpt-tokenizer.dev/ for encoding names
        max_tokens: int = 4096,  # Azure gpt-4o max tokens defaults to 4096
        overlap: int = 100,
        submission_container: str = "msft-quarterly-earnings",
        results_container: str = "msft-quarterly-earnings-di-results",
        run_id: Optional[str] = None,
        **kwargs: Any,
    ) -> None:
        # Fetch config values from env
        fetcher = EnvFetcher()
        # DI
        self.di_client = get_doc_analysis_client(DIConfig.fetch(fetcher))
        self.overwrite_di = fetcher.get_bool("OVERWRITE_DI_RESULTS", False)

        # LLM
        self.llm = get_chat_completions_client(AzureOpenAIConfig.fetch(fetcher))

        # Azure Storage
        self.blob_client = get_blob_service_client(AzureStorageConfig.fetch(fetcher), DefaultAzureCredential())
        self.submission_container = submission_container
        self.results_continer = results_container

        # DB
        self.db_config = CitationDBConfig.fetch(
            fetcher=fetcher, question_id=db_question_id, creator="llm-citation-generator", run_id=run_id
        )

        # Prompts
        system_prompt_template = load_template(PROMPT_TEMPLATES_DIR.joinpath(system_prompt_file))
        self.system_prompt = system_prompt_template.render(question=question)
        self.user_prompt_template = load_template(PROMPT_TEMPLATES_DIR.joinpath(user_prompt_file))
        # Get token count without context to calculate max context tokens
        max_context_tokens = get_context_max_tokens(
            text=self.system_prompt + self.user_prompt_template.render(question=question),
            encoding_name=token_encoding_name,
            max_tokens=max_tokens,
        )
        self.question = question

        # Chunking
        self.chunker = AnalyzedDocChunker(
            max_tokens=max_context_tokens,
            encoding_name=token_encoding_name,
            overlap=overlap,
        )

    def __call__(self, submission_folder: str, **kwargs: Any) -> dict:
        output: dict = {}

        docs = analyze_submission_folder(
            blob_service_client=self.blob_client,
            folder_name=submission_folder,
            di_client=self.di_client,
            submission_container=self.submission_container,
            results_container=self.results_continer,
            overwrite_di_results=self.overwrite_di,
        )

        if len(docs) == 0:
            raise ValueError(f"No documents found for submission {submission_folder}")

        logger.debug(f"Found {len(docs)} documents for submission {submission_folder}")

        chunked_docs = self.chunker.chunk_by_token(docs=docs)

        citations: list[InvalidCitation | ValidCitation] = []
        docs_len = len(chunked_docs)
        # loop through each document's chunks and call llm
        for doc_idx, cd in enumerate(chunked_docs):
            logger.debug(f"Chunked document: {cd.document_name}")

            chunk_len = len(cd.chunks)
            for chunk_idx, doc_chunk in enumerate(cd.chunks):
                logger.debug(f"Sending chunk {chunk_idx+1} of {chunk_len} for doc {doc_idx+1} of {docs_len} to LLM")

                llm_response = self._generate_citations(doc_chunk)

                validated_citations = self._validate_citations(llm_response, cd.document_name, doc_chunk)
                citations.extend(validated_citations)

        output["citations"] = [asdict(c) for c in citations]

        if self.db_config is not None:
            # remove invalid citations
            valid_citations = [c for c in citations if isinstance(c, ValidCitation)]

            form_name = f"{submission_folder}{self.db_config.form_suffix}"
            logger.info(f"Adding {len(citations)} citations to form {form_name}")

            form_id = commit_forms_docs_citations_to_db(
                conn_str=self.db_config.conn_str,
                form_name=form_name,
                question_id=self.db_config.question_id,
                docs=docs,
                creator=self.db_config.creator,
                citations=valid_citations,
            )
            output["db_form_id"] = form_id
            output["db_question_id"] = self.db_config.question_id

        return output

    def _generate_citations(self, chunk: str) -> str:
        """
        Generates citations based on the provided text chunk.

        Args:
            chunk (str): The text chunk to be used as context for generating citations.

        Returns:
            str: The generated citations in JSON format.
        """
        # add chunk as context
        user_prompt = self.user_prompt_template.render(context=chunk, question=self.question)

        msgs = [
            SystemMessage(content=self.system_prompt),
            UserMessage(content=user_prompt),
        ]
        completion = self.llm.complete(
            messages=msgs,
            response_format="json_object",
            seed=42,
            temperature=0,
        )
        return completion.choices[0].message.content

    def _validate_citations(
        self, llm_response: str, doc_name: str, chunk: str
    ) -> list[InvalidCitation | ValidCitation]:
        citations: list[InvalidCitation | ValidCitation] = []
        loaded_citations = json.loads(llm_response)
        citations_to_validate: list = loaded_citations.get("citations", [])

        logger.debug(f"Validating {len(citations_to_validate)} citations")
        for c in citations_to_validate:
            if isinstance(c, dict):
                excerpt = c.get("excerpt")
                # if excerpt is None, the citation is invalid
                if excerpt is None:
                    citations.append(
                        InvalidCitation(
                            document_name=doc_name,
                            raw=llm_response,
                            error="Invalid citation format",
                        )
                    )
                    continue

                citation = Citation(
                    excerpt=excerpt,
                    document_name=doc_name,
                    explanation=c.get("explanation"),
                )
                # validate citation
                validated_citation = validate_citation(citation=citation, chunk=chunk)
                citations.append(validated_citation)
            else:
                # if the citation is not a dict, it is invalid
                citations.append(
                    InvalidCitation(
                        document_name=doc_name,
                        raw=llm_response,
                        error="Invalid citation format",
                    )
                )
        return citations


if __name__ == "__main__":
    from orchestrator.run_experiment import load_experiments
    from orchestrator.telemetry_utils import configure_telemetry
    from orchestrator.utils import new_run_id

    configure_telemetry()  # local telemetry

    # update values as needed
    submission_folder = "F24Q3"
    variants = ["total-revenue/1.yaml"]
    write_to_file = False

    run_id = new_run_id()
    experiments = load_experiments(
        config_filepath="llm_citation_generator/config/experiment.yaml", variants=variants, run_id=run_id
    )
    for experiment in experiments:
        result = experiment.run(submission_folder=submission_folder)
        if write_to_file:
            experiment.write_results([result])
    logger.info(f"Run ID: {run_id}")
