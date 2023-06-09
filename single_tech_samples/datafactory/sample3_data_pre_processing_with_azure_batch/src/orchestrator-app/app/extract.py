"""
extract.py is the main file which will be invoked from ADF custom batch activity for extraction process.
"""
from os import path


import datetime
import argparse
import logging

from core.extract.extractscheduler import ExtractScheduler
from core.batch.task import Task
from core.batch.job import Job
from core.config import getSettings
from utils.confighelper import ConfigHelper

if __name__ == '__main__':

    try:
        parser = argparse.ArgumentParser()
        parser.add_argument("--inputFile", "-i", help="Set the raw path")
        parser.add_argument(
            "--outputPath", "-o", help="Set the output path"
        )
        
        args = parser.parse_args()


        settings = getSettings()
        configHelper=ConfigHelper()
        log = logging.getLogger(__name__)
        task = Task()
        job = Job()
        configHelper = ConfigHelper()
        
        log.info(f"Environment : {settings.RUN_ENVIRONMENT}")

        start_time = datetime.datetime.now().replace(microsecond=0)
        log.info(f"Extraction start time: {start_time}")
        
        #Extract the given bag file
        extractionScheduler = ExtractScheduler(job=job, task=task)
        jobs = extractionScheduler.scheduleExtraction(
            inputFile=args.inputFile,
            outputPath=args.outputPath, 
            poolId=settings.AZ_BATCH_EXECUTION_POOL_ID
        )

        # Execution will wait for 10 minutes to monitor task execution before terminating gracefully.
        # You can configure it based on your ideal processing time.
        job.monitorJobsToComplete(
            jobs=jobs, timeout=datetime.timedelta(minutes=10)
        )

        end_time = datetime.datetime.now().replace(microsecond=0)

        log.info(f"Extraction completion time: {end_time}")
        elapsed_time = end_time - start_time
        log.info(f"Elapsed time: {elapsed_time}")

    except Exception as e:
        raise RuntimeError(f"Error: {e.__class__}")

