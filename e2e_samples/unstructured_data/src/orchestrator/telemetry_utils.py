import logging
import os
from typing import Optional

from azure.monitor.opentelemetry import configure_azure_monitor
from opentelemetry import trace
from opentelemetry.instrumentation.openai import OpenAIInstrumentor
from opentelemetry.sdk.resources import SERVICE_NAME, Resource

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

tracer = trace.get_tracer(__name__)

DEFAULT_OTEL_SERVICE_NAME = "private-dno-experiments"
APP_INSIGHTS = "APP_INSIGHTS"
LOCAL = "LOCAL"


def instrument() -> None:
    # turn off logging prompts, completions, and embeddings to span attributes
    os.environ["TRACELOOP_TRACE_CONTENT"] = "false"
    OpenAIInstrumentor(upload_base64_image=None).instrument()


def configure_telemetry(environment: Optional[str] = LOCAL) -> None:
    """
    Configures telemetry based on the specified environment.
    Parameters:
    environment (Optional[str]): The environment for which to configure telemetry.
                                 Accepted values are APP_INSIGHTS or LOCAL.
                                 Defaults to LOCAL.
    Raises:
    ValueError: If the environment is APP_INSIGHTS and the
                APPLICATIONINSIGHTS_CONNECTION_STRING environment variable is not set.
    Behavior:
    - If the environment is APP_INSIGHTS, configures telemetry for Azure Monitor
      using the connection string from the APPLICATIONINSIGHTS_CONNECTION_STRING
      environment variable.
    - If the environment is LOCAL, configures local tracing.
    - If the environment is not recognized, prints an error message indicating the
        accepted values.
    """
    if environment == APP_INSIGHTS:
        conn_str = os.getenv("APPLICATIONINSIGHTS_CONNECTION_STRING")
        if conn_str is None:
            raise ValueError(
                "Unable to configure Azure Monitor. \
                Please set APPLICATIONINSIGHTS_CONNECTION_STRING environment variable"
            )
        resource = Resource(attributes={SERVICE_NAME: os.getenv("OTEL_SERVICE_NAME", DEFAULT_OTEL_SERVICE_NAME)})
        logger.info("Configuring telemetry for Azure Monitor")
        configure_azure_monitor(connection_string=conn_str, resource=resource)
        instrument()
    elif environment == LOCAL:
        from promptflow.tracing import start_trace

        logger.info("Configuring local tracing")
        start_trace()
    elif environment is not None:
        logger.info(
            f"Unknown telemetry environment of {environment}. \
              Accepted values are {APP_INSIGHTS} or {LOCAL}"
        )
