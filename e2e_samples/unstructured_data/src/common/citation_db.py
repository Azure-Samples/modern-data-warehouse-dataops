import logging
import random
import string
import struct

import pyodbc
from azure.identity import DefaultAzureCredential
from common.analyze_submissions import AnalyzedDocument
from common.citation_generator_utils import Citation

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)


def get_conn(conn_str: str) -> pyodbc.Connection:
    credential = DefaultAzureCredential()
    token_bytes = credential.get_token("https://database.windows.net/.default").token.encode("UTF-16-LE")
    token_struct = struct.pack(f"<I{len(token_bytes)}s", len(token_bytes), token_bytes)
    SQL_COPT_SS_ACCESS_TOKEN = 1256  # This connection option is defined by microsoft in msodbcsql.h
    return pyodbc.connect(conn_str, attrs_before={SQL_COPT_SS_ACCESS_TOKEN: token_struct})


def commit_to_db(
    conn_str: str,
    form_name: str,
    question_id: int,
    docs: list[AnalyzedDocument],
    creator: str,
    citations: list[Citation],
) -> int:
    try:
        conn = get_conn(conn_str)
        cursor = conn.cursor()

        template_id = get_template_id_by_question_id(cursor=cursor, question_id=question_id)

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
        cursor.close()
        conn.close()


def get_template_id_by_question_id(cursor: pyodbc.Cursor, question_id: int) -> int:
    query = """
    SELECT templateId FROM dbo.question
    WHERE questionId = ?;
    """
    cursor.execute(query, (question_id))
    template_id = cursor.fetchone()
    if template_id is None:
        raise ValueError(f"Question with question_id: {question_id} does not exist")
    return template_id[0]


def create_citations(
    conn: pyodbc.Connection,
    cursor: pyodbc.Cursor,
    form_id: int,
    question_id: int,
    citations: list[Citation],
    creator: str,
    docs_name_id_map: dict,
) -> None:
    logger.info(f"Creating {len(citations)} citations for form_id: {form_id}")
    for c in citations:
        doc_id = docs_name_id_map[c.document_name]

        # TODO: update citation id creation
        citation_id = "".join(random.choice(string.ascii_letters) for _ in range(12))

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


def create_template(
    cursor: pyodbc.Cursor, conn: pyodbc.Connection, template_name: str, creator: str = "citation-generator"
) -> int:
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
