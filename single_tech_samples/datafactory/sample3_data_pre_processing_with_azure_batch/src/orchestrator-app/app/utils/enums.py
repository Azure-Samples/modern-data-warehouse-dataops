"""Define all the enums here
"""
from enum import Enum


class DataStreamState(Enum):
    """Enum values for daatstream state.
    """
    PROCESSING = "PROCESSING"
    COMPLETED = "COMPLETED"
    

class RunEnvironment(Enum):
    """Enum values for run environment    
    """
    LOCAL = "LOCAL"
    CLOUD = "CLOUD"
    
