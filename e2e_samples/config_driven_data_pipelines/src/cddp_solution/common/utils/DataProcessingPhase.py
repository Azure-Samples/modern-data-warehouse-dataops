from enum import Enum


class DataProcessingPhase(Enum):
    """

    Enumerations for different data processing phases, they are:
       - LANDING_TO_STAGING
       - STAGING_TO_STANDARD
       - STANDARD_TO_SERVING

    Parameters
    ----------
    Enum : Enum
        Generic enumeration.

    """

    MASTER_LANDING_TO_STAGING = "MASTER_LANDING_TO_STAGING"
    MASTER_STAGING_TO_STANDARD = "MASTER_STAGING_TO_STANDARD"
    MASTER_STANDARD_TO_SERVING = "MASTER_STANDARD_TO_SERVING"
    EVENT_LANDING_TO_STAGING = "EVENT_LANDING_TO_STAGING"
    EVENT_STAGING_TO_STANDARD = "EVENT_STAGING_TO_STANDARD"
    EVENT_STANDARD_TO_SERVING = "EVENT_STANDARD_TO_SERVING"
