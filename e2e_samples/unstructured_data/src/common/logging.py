import logging
from typing import Optional

from common.env import EnvValueFetcher

DEFAULT_LOG_LEVEL = EnvValueFetcher().get("LOG_LEVEL") or "INFO"


def get_logger(name: str, level: Optional[str] = None) -> logging.Logger:
    """
    Get a logger with the specified level.
    """
    if level is None:
        level = DEFAULT_LOG_LEVEL

    level = level.upper()

    logger = logging.getLogger(name)
    logger.setLevel(level)

    return logger
