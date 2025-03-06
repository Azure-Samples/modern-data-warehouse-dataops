import os

from dotenv import load_dotenv

load_dotenv()

# logs
LOG_LEVEL = os.getenv("EXPERIMENT_LOG_LEVEL", "INFO")

# directories
EVALUATORS_DIR = os.getenv("EVALUATORS_DIR")
EXPERIMENTS_DIR = os.getenv("EXPERIMENTS_DIR")
RUN_OUTPUTS_DIR = os.getenv("RUN_OUTPUTS_DIR")
