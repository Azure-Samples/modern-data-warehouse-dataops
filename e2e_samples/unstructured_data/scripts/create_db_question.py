# usage:
# python ./scripts/create_db_question.py --template-id <template-id> --prefix <question-prefix> --text <question-text> # noqa: E501
# python ./scripts/create_db_question.py -i 1 -p 3 -t "test question 3"


if __name__ == "__main__":
    import argparse
    import logging

    from common.citation_db import (
        CitationDBConfig,
        CitationDBOptions,
        create_question,
        create_template_question_lockfile,
        get_conn,
    )
    from common.config_utils import EnvFetcher
    from common.logging import get_logger

    logging.basicConfig()
    logger = get_logger(__name__)

    parser = argparse.ArgumentParser()
    parser.add_argument("-i", "--template-id", required=True, help="The template_id of the template")
    parser.add_argument("-p", "--prefix", required=True, help="The prefix for the question")
    parser.add_argument("-t", "--text", required=True, help="The text of the question")
    parser.add_argument(
        "-c", "--creator", default="llm-citation-generator", help="The creator of the template and questions"
    )
    args = parser.parse_args()
    template_id = args.template_id
    prefix = args.prefix
    text = args.text
    creator = args.creator
    config = CitationDBConfig.fetch(fetcher=EnvFetcher(), options=CitationDBOptions(creator=creator))

    conn = None
    cursor = None
    try:
        conn = get_conn(config.conn_str)
        cursor = conn.cursor()
        question_id = create_question(
            cursor=cursor,
            conn=conn,
            template_id=template_id,
            prefix=prefix,
            text=text,
            creator=config.options.creator,
        )
        logger.info(f"Created question with id: {question_id}")
        path = create_template_question_lockfile(
            cursor=cursor,
            template_id=template_id,
        )
        logger.info(f"Updated template question lockfile at path {path}")
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()
