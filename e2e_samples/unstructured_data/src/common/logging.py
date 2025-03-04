import logging
from typing import Optional

from common.config_utils import EnvFetcher

DEFAULT_LOG_LEVEL = EnvFetcher().get("EXPERIMENT_LOG_LEVEL") or "INFO"


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
