import datetime
import logging

import azure.functions as func
from .configuration import Configuration
from .data_share_helper import DataShareHelper


def main(mytimer: func.TimerRequest) -> None:
    utc_timestamp = (
        datetime.datetime.utcnow().replace(tzinfo=datetime.timezone.utc).isoformat()
    )

    config = Configuration()

    data_share_helper = DataShareHelper(config)
    data_share_helper.accept_invitation()

    if mytimer.past_due:
        logging.info("The timer is past due!")

    logging.info("Python timer trigger function ran at %s", utc_timestamp)
