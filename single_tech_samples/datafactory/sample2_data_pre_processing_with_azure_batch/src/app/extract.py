"""
extract.py is the main file which will be invoked from ADF custom batch activity for extraction process.
"""
from os import path


import datetime
import argparse
import logging
import logging.config

from os import path

import logging
from core.extract.extractscheduler import ExtractScheduler
from core.batch.task import Task
from core.batch.job import Job
from core.config import getSettings
from utils.storageclient import StorageClient
from utils.confighelper import ConfigHelper


settings = getSettings()
configHelper = ConfigHelper()

def extract(cargs):
    task = Task()
    job = Job()
    configHelper = ConfigHelper()
    logging.basicConfig(level=logging.INFO)
    logger = logging.getLogger(__name__)

    start_time = datetime.datetime.now().replace(microsecond=0)
    logger.info(f"Extraction start time: {start_time}")
    # Process rosbag for extraction.
    extractionScheduler = ExtractScheduler(
        job=job, task=task, settings=settings)

    jobs = extractionScheduler.scheduleExtraction(
        rawPath=args.rawPath, extractedPath=args.extractedPath, poolId=settings.AZ_BATCH_EXECUTION_POOL_ID
    )

    # Monitor Extraction jobs. Threshold is in minutes
    # Execution will wait for configured minutes to monitor task execution before terminating gracefully.
    job.monitorJobsToComplete(
        jobs=jobs, timeout=datetime.timedelta(minutes=2)
    )

    # Extraction complete
   
    
    end_time = datetime.datetime.now().replace(microsecond=0)
    
    logger.info(f"Extraction completion time: {end_time}")
    elapsed_time = end_time - start_time
    logger.info(f"Elapsed time: {elapsed_time}")


if __name__ == '__main__':

    try:
        parser = argparse.ArgumentParser()
        parser.add_argument("--rawPath", "-rPath",
                            help="Set the input file path")
        parser.add_argument("--extractedPath", "-ePath",
                            help="Set the input file path")

        args = parser.parse_args()
        extract(args)

    except Exception as e:
        raise RuntimeError(f"Error: {e.__class__}")
