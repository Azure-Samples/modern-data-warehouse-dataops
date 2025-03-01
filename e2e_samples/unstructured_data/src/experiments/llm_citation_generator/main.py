import json
from dataclasses import asdict
from pathlib import Path
from typing import Any, Optional

from azure.ai.inference.models import SystemMessage, UserMessage
from azure.identity import DefaultAzureCredential
from common.analyze_submissions import AnalyzedDocument, analyze_submission_folder
from common.azure_storage_utils import get_blob_service_client
from common.chunking import AnalyzedDocChunker, get_context_max_tokens
from common.citation import Citation, InvalidCitation, ValidCitation
from common.citation_db import commit_forms_docs_citations_to_db
from common.citation_generator_utils import validate_citation
from common.config import AzureOpenAIConfig, AzureStorageConfig, DIConfig, get_citation_db_config
from common.di_utils import get_doc_analysis_client
from common.llm import get_chat_completions_client
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
        aoai_config: Optional[AzureOpenAIConfig] = None,
        di_config: Optional[DIConfig] = None,
        az_storage_config: Optional[AzureStorageConfig] = None,
        db_conn_string: Optional[str] = None,
        submission_container: str = "msft-quarterly-earnings",
        results_container: str = "msft-quarterly-earnings-di-results",
        run_id: Optional[str] = None,
        **kwargs: Any,
    ) -> None:
        self.question = question

        # Prompts
        system_prompt_template = load_template(PROMPT_TEMPLATES_DIR.joinpath(system_prompt_file))
        self.system_prompt = system_prompt_template.render(question=question)
        self.user_prompt_template = load_template(PROMPT_TEMPLATES_DIR.joinpath(user_prompt_file))
        # get token count without context to calculate max context tokens
        max_context_tokens = get_context_max_tokens(
            text=self.system_prompt + self.user_prompt_template.render(question=question),
            encoding_name=token_encoding_name,
            max_tokens=max_tokens,
        )

        # Chunking
        self.chunker = AnalyzedDocChunker(
            max_tokens=max_context_tokens,
            encoding_name=token_encoding_name,
            overlap=overlap,
        )

        # Blob
        self.blob_client = get_blob_service_client(az_storage_config, DefaultAzureCredential())
        self.submission_container = submission_container
        self.results_continer = results_container

        # DI
        self.di_client = get_doc_analysis_client(di_config)

        # LLM
        self.llm = get_chat_completions_client(aoai_config)

        # DB
        self.db_config = get_citation_db_config(
            creator="llm-citation-generator", conn_str=db_conn_string, question_id=db_question_id, run_id=run_id
        )

    def __call__(self, submission_folder: str, **kwargs: Any) -> dict:
        if self.db_config is not None:
            db_question_id = self.db_config.question_id
        else:
            db_question_id = None
        output: dict = {"citations": [], "db_form_id": None, "db_question_id": db_question_id}

        docs = analyze_submission_folder(
            blob_service_client=self.blob_client,
            folder_name=submission_folder,
            di_client=self.di_client,
            submission_container=self.submission_container,
            results_container=self.results_continer,
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

                llm_response = self.get_citations(doc_chunk)

                validated_citations = self._validate_citations(llm_response, cd.document_name, doc_chunk)
                citations.extend(validated_citations)

        output["citations"] = [asdict(c) for c in citations]

        output["db_info"] = self.write_to_db(submission_folder=submission_folder, docs=docs, citations=citations)
        return output

    def get_citations(self, chunk: str) -> str:
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

                validated_citation = validate_citation(citation=citation, chunk=chunk)
                citations.append(validated_citation)
            else:
                citations.append(
                    InvalidCitation(
                        document_name=doc_name,
                        raw=llm_response,
                        error="Invalid citation format",
                    )
                )
        return citations

    def write_to_db(
        self, submission_folder: str, docs: list[AnalyzedDocument], citations: list[ValidCitation | InvalidCitation]
    ) -> Optional[dict]:
        if self.db_config is None:
            return None

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
        return {"form_id": form_id, "question_id": self.db_config.question_id}


if __name__ == "__main__":
    from dotenv import load_dotenv
    from orchestrator.run_experiment import load_experiments
    from orchestrator.telemetry_utils import configure_telemetry
    from orchestrator.utils import new_run_id

    load_dotenv(override=True)
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
