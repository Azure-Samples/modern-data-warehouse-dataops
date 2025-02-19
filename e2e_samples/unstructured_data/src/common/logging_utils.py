import logging

from common.env import LOG_LEVEL


def get_logger(name: str) -> logging.Logger:

    logger = logging.getLogger(name)
    logger.setLevel(LOG_LEVEL)
    return logger
