import random
import string
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Optional

import pyodbc
import yaml
from common.analyze_submissions import AnalyzedDocument
from common.citation import ValidCitation
from common.config_utils import Fetcher
from common.logging import get_logger
from common.path_utils import RepoPaths

logger = get_logger(__name__)


@dataclass
class DBQuestion:
    prefix: str
    text: str


@dataclass
class CitationDBOptions:
    form_suffix: str
    creator: str

    def __init__(self, creator: str, form_suffix: Optional[str] = None) -> None:
        self.form_suffix = form_suffix or ""
        self.creator = creator


@dataclass
class CitationDBConfig:
    conn_str: str
    options: CitationDBOptions

    @classmethod
    def fetch(cls, fetcher: Fetcher, options: CitationDBOptions) -> "CitationDBConfig":
        conn_str = fetcher.get_strict("CITATION_DB_CONNECTION_STRING")
        return cls(conn_str=conn_str, options=options)


def get_conn(conn_str: str) -> pyodbc.Connection:
    return pyodbc.connect(conn_str)


def commit_forms_docs_citations_to_db(
    conn_str: str,
    form_name: str,
    question_id: int,
    docs: list[AnalyzedDocument],
    creator: str,
    citations: list[ValidCitation],
) -> int:
    conn = None
    cursor = None
    try:
        conn = get_conn(conn_str)
        cursor = conn.cursor()

        template_id = get_question_template_id(cursor=cursor, question_id=question_id)

        # get form_id, create form if it does not exist
        form_id = get_or_create_form_id(
            cursor=cursor,
            conn=conn,
            form_name=form_name,
            template_id=template_id,
            creator=creator,
        )

        # create docs if not exist
        docs_name_id_map = get_or_create_document_ids(
            cursor=cursor, conn=conn, docs=docs, form_id=form_id, creator=creator
        )

        # create citations
        create_citations(
            cursor=cursor,
            conn=conn,
            form_id=form_id,
            question_id=question_id,
            citations=citations,
            creator=creator,
            docs_name_id_map=docs_name_id_map,
        )
        return form_id
    finally:
        if cursor is not None:
            cursor.close()
        if conn is not None:
            conn.close()


def get_question_template_id(cursor: pyodbc.Cursor, question_id: int) -> int:
    query = """
    SELECT templateId FROM dbo.question
    WHERE questionId = ?;
    """
    cursor.execute(query, (question_id))
    template_id = cursor.fetchone()
    return template_id[0]


def create_citations(
    conn: pyodbc.Connection,
    cursor: pyodbc.Cursor,
    form_id: int,
    question_id: int,
    citations: list[ValidCitation],
    creator: str,
    docs_name_id_map: dict,
) -> None:
    logger.info(f"Creating {len(citations)} citations for form_id: {form_id}")
    for c in citations:
        doc_id = docs_name_id_map[c.document_name]

        # TODO: update citation id creation
        citation_id = "".join(random.choice(string.ascii_letters) for _ in range(8))

        query = """
        INSERT INTO dbo.citation
        (citationId, formId, questionId,
        documentId, excerpt, creator)
        VALUES (?, ?, ?, ?, ?, ?)
        """
        cursor.execute(query, (citation_id, form_id, question_id, doc_id, f"{c.excerpt}", creator))
    conn.commit()


def get_or_create_form_id(
    cursor: pyodbc.Cursor, conn: pyodbc.Connection, form_name: str, template_id: int, creator: str
) -> int:
    form_id = get_form_id_by_name(cursor=cursor, form_name=form_name, template_id=template_id)
    if form_id is not None:
        logger.info(f"Using existing Form. formId: {form_id}, formName: {form_name}")
        return form_id

    return create_form(
        cursor=cursor,
        conn=conn,
        form_name=form_name,
        template_id=template_id,
        creator=creator,
    )


def create_form(cursor: pyodbc.Cursor, conn: pyodbc.Connection, form_name: str, template_id: int, creator: str) -> int:
    query = """
    INSERT INTO dbo.form (templateId, formName, creator)
    OUTPUT Inserted.formId
    VALUES (?, ?, ?);
    """
    cursor.execute(query, (template_id, form_name, creator))
    form_id = cursor.fetchval()
    conn.commit()

    logger.info(f"Created Form. formId: {form_id}, formName: {form_name}")
    return form_id


def get_form_id_by_name(cursor: pyodbc.Cursor, form_name: str, template_id: int) -> int | None:
    # TODO: We need to database to enable querying by form_name
    # and it should be unique to a template
    query = """
    SELECT formId, formName FROM dbo.form
    WHERE templateId = (?)
    """
    cursor.execute(query, (template_id))
    forms = cursor.fetchall()

    for row in forms:
        # if form_name matches return form_id
        if row[1] == form_name:
            return row[0]
    return None


def get_or_create_document_ids(
    cursor: pyodbc.Cursor, conn: pyodbc.Connection, docs: list[AnalyzedDocument], form_id: int, creator: str
) -> dict:
    docs_name_id_map = {}
    # check if docs exists,
    # This will create new docs even if the docs exist with another form
    # We need a way to get the doc id. We can't search by name because
    # it's a text field and that would mean that a doc name has to be
    # unique for the whole DB.
    query = """
    SELECT documentId, name from dbo.document
    WHERE formId = (?)
    """
    cursor.execute(query, (form_id))
    found_docs = cursor.fetchall()
    # add docs to map
    for row in found_docs:
        doc_id = row[0]
        doc_name = row[1]
        docs_name_id_map[doc_name] = doc_id
        logger.info(f"Using existing Document. documentId: {doc_id}, name: {doc_name}")

    for doc in docs:
        existing_doc_id = docs_name_id_map.get(doc.document_name)
        # if doc doesn't exist, create it
        if existing_doc_id is None:
            query = """
            INSERT INTO dbo.document (formId, name, pdfUrl, diUrl, creator)
            OUTPUT Inserted.documentId
            VALUES (?, ?, ?, ?, ?)
            """
            cursor.execute(query, (form_id, doc.document_name, doc.doc_url, doc.di_url, creator))

            new_doc_id = cursor.fetchval()
            conn.commit()
            logger.info(
                f"Created new Document: documentId: {new_doc_id}, \
                    name: {doc.document_name}"
            )

            docs_name_id_map[doc.document_name] = new_doc_id
    return docs_name_id_map


def get_template_by_id(cursor: pyodbc.Cursor, template_id: int) -> Any:
    query = """
    SELECT * FROM dbo.template
    WHERE templateId = ?;
    """
    cursor.execute(query, (template_id,))
    template = cursor.fetchone()
    return template


def create_template(cursor: pyodbc.Cursor, conn: pyodbc.Connection, template_name: str, creator: str) -> int:
    query = """
    INSERT into dbo.template (templateName, creator)
    OUTPUT Inserted.templateId
    VALUES (?, ?);
    """
    cursor.execute(query, (template_name, creator))
    template_id = cursor.fetchval()
    conn.commit()
    return template_id


def create_question(
    cursor: pyodbc.Cursor,
    conn: pyodbc.Connection,
    template_id: int,
    prefix: str,
    text: str,
    creator: str = "citation-generator",
) -> int:
    query = """
    INSERT INTO dbo.question (templateId, prefix, text, creator)
    OUTPUT Inserted.questionId
    VALUES (?, ?, ?, ?);
    """
    cursor.execute(query, (template_id, prefix, text, creator))
    question_id = cursor.fetchval()
    conn.commit()
    return question_id


def create_template_and_questions(
    config: CitationDBConfig, template_name: str, questions: list[DBQuestion]
) -> tuple[Path, int]:
    conn = None
    cursor = None
    try:
        conn = get_conn(config.conn_str)
        cursor = conn.cursor()
        template_id = create_template(
            cursor=cursor, conn=conn, template_name=template_name, creator=config.options.creator
        )
        for question in questions:
            create_question(
                cursor=cursor,
                conn=conn,
                template_id=template_id,
                prefix=question.prefix,
                text=question.text,
                creator=config.options.creator,
            )
        path = create_template_question_lockfile(
            cursor=cursor,
            template_id=template_id,
        )
        return path, template_id
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()


def get_template_questions(cursor: pyodbc.Cursor, template_id: int) -> list:
    query = """
    SELECT q.* FROM dbo.question q
    JOIN dbo.template t ON q.templateId = t.templateId
    WHERE t.templateId = (?)
    """
    cursor.execute(query, (template_id))
    return cursor.fetchall()


def create_template_question_lockfile(
    cursor: pyodbc.Cursor, template_id: int, output_dir: Optional[Path] = None
) -> Path:
    if output_dir is None:
        output_dir = RepoPaths.data.joinpath("citationdb")

    output_template_data = {}
    db_template = get_template_by_id(cursor, template_id)
    print(db_template)
    template_col_names = [c[0] for c in cursor.description]
    for i, c in enumerate(template_col_names):
        output_template_data[c] = db_template[i]

    output_questions_data = []
    db_questions = get_template_questions(cursor, template_id)
    questions_col_names = [c[0] for c in cursor.description]
    for q in db_questions:
        question_data = {}
        for i, c in enumerate(questions_col_names):
            question_data[c] = q[i]
        output_questions_data.append(question_data)

    data = {"template": output_template_data, "questions": output_questions_data}
    output_path = output_dir.joinpath(f"template_{template_id}.lock.yaml")
    # create directory if it does not exist
    output_dir.mkdir(parents=True, exist_ok=True)
    with open(output_path, "w") as f:
        yaml.dump(data, f)
    return output_path
