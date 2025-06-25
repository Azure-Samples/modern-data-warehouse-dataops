# usage:
# python ./scripts/populate_db.py
# python ./scripts/populate_db.py --name <template-name> --creator <creator>
# python ./scripts/populate_db.py -n test-template --creator llm-citation-generator

# By default, the template name is "template-1" and the creator is "llm-citation-generator".

if __name__ == "__main__":
    import argparse
    import logging

    from common.citation_db import CitationDBConfig, CitationDBOptions, DBQuestion, create_template_and_questions
    from common.config_utils import EnvFetcher
    from common.logging import get_logger

    logging.basicConfig()
    logger = get_logger(__name__)

    parser = argparse.ArgumentParser()
    parser.add_argument("-n", "--name", default="template-1", help="The name of the template to create")
    parser.add_argument(
        "-c", "--creator", default="llm-citation-generator", help="The creator of the template and questions"
    )
    args = parser.parse_args()
    template_name = args.name
    creator = args.creator

    config = CitationDBConfig.fetch(fetcher=EnvFetcher(), options=CitationDBOptions(creator=creator))
    questions = [
        DBQuestion(
            prefix="1",
            text="What was the company’s revenue for this quarter of this Fiscal Year?",
        ),
        DBQuestion(prefix="2", text="What are the earnings per share (EPS) for this quarter?"),
    ]

    path, templates_id = create_template_and_questions(config=config, template_name=template_name, questions=questions)
    logger.info(f"Updated template question lockfile at path {path}")
    logger.info(f"Created template {template_name} with id: {templates_id}")
