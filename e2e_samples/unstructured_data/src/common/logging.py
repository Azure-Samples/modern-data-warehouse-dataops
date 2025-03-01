import logging
from typing import Optional

from common.env import LOG_LEVEL


def get_logger(name: str, level: Optional[str] = None) -> logging.Logger:
    """
    Get a logger with the specified level.
    """
    if level is None:
        level = LOG_LEVEL or "INFO"
    level = level.upper()

    logger = logging.getLogger(name)
    logger.setLevel(level)

    return logger
