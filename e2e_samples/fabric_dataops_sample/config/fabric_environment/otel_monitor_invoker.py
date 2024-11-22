# This examples uses advanced config using monitor exporters using:
# ref: https://github.com/Azure/azure-sdk-for-python/tree/main/sdk/monitor/azure-monitor-opentelemetry-exporter#microsoft-opentelemetry-exporter-for-azure-monitor

# Simple configuration could also be done using as below in which case, tracer, logger and meter are
#    pre-configured to send data to azure-monitor.
# ref: https://learn.microsoft.com/en-us/azure/azure-monitor/app/opentelemetry-enable?tabs=python
# ```
# from azure.monitor.opentelemetry import configure_azure_monitor

# # Configure the Distro to authenticate with Azure Monitor - without managed identity
# configure_azure_monitor(
#     connection_string="your-connection-string"
# )

# # using a managed identity credential.
# configure_azure_monitor(
#     connection_string="your-connection-string",
#     credential=ManagedIdentityCredential(),
# )
# ```
# - https://learn.microsoft.com/en-us/python/api/overview/azure/monitor-opentelemetry-exporter-readme?view=azure-python-preview
# - https://learn.microsoft.com/en-us/python/api/overview/azure/monitor-opentelemetry-exporter-readme?view=azure-python-preview#examples

import logging

# from azure.monitor.opentelemetry import configure_azure_monitor # We are using the advanced
#    configs shown below using AzureMonitor*Exporter.
from azure.monitor.opentelemetry.exporter import (
    AzureMonitorLogExporter,
    AzureMonitorMetricExporter,
    AzureMonitorTraceExporter,
)

# metrics
# traces
from opentelemetry import metrics, trace

# logs
from opentelemetry.sdk._logs import LoggerProvider, LoggingHandler
from opentelemetry.sdk._logs.export import BatchLogRecordProcessor
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor

logging.basicConfig(level=logging.INFO)


class OpenTelemetryAppInsightsExporter:
    def __init__(self, conn_string: str) -> None:
        """
        Initializes the OpenTelemetryExporter class.

        Args:
            conn_string (str): Azure AppInsights connection string.
        """
        self.conn_string = conn_string

        return None

    def get_otel_tracer(self, trace_resource_attributes: dict, tracer_name: str = __name__) -> object:
        """
        Creates and returns an OpenTelemetry tracer object.

        Args:
            trace_resource_attributes (dict): The OpenTelemetry resource attributes in dictionary format
            tracer_name (str): The name of the tracer. Default is __name__.
        Returns:
            tracer: OpenTelemetry tracer object
        """
        resource = Resource(attributes=trace_resource_attributes)
        tracer_provider = TracerProvider(resource=resource)
        # Exporter to send data to AppInsights
        trace_exporter = AzureMonitorTraceExporter(connection_string=self.conn_string)
        span_processor = BatchSpanProcessor(trace_exporter)
        tracer_provider.add_span_processor(span_processor)
        tracer = trace.get_tracer(tracer_name, tracer_provider=tracer_provider)

        return tracer

    def get_otel_logger(
        self, log_resource_attributes: dict, logger_name: str = __name__, add_console_handler: bool = True
    ) -> object:
        """
        Creates and returns an OpenTelemetry logger object.

        Args:
            log_resource_attributes (dict): The OpenTelemetry resource attributes in dictionary format
            logger_name (str): The name of the logger. Default is __name__.
            add_console_handler (bool): Whether to add a console handler to the logger. Default is True.
        Returns:
            logger: OpenTelemetry logger object
        """
        resource = Resource(attributes=log_resource_attributes)
        log_exporter = AzureMonitorLogExporter(connection_string=self.conn_string)

        logger_provider = LoggerProvider(resource=resource)
        logger_provider.add_log_record_processor(BatchLogRecordProcessor(log_exporter))
        handler = LoggingHandler(level=logging.INFO, logger_provider=logger_provider)
        logging.getLogger().addHandler(handler)  # Attach OTLP handler to root logger

        logger = logging.getLogger(logger_name)  # get namespaced logger

        # # Create a console handler  - Optional
        if add_console_handler:
            console_handler = logging.StreamHandler()
            console_handler.setLevel(logging.INFO)
            logger.addHandler(console_handler)

        return logger

    def get_otel_metrics(
        self, metric_resource_attributes: dict, metric_name: str = __name__, metric_version: str = "0"
    ) -> object:
        """
        Creates and returns an OpenTelemetry metrics object.

        Args:
            metric_resource_attributes (dict): The OpenTelemetry resource attributes in dictionary format
            metric_name (str): The name of the metric. Default is __name__.
            metric_version (str): The version of the metric. Default is "0".
        Returns:
            meter: OpenTelemetry meter object
        """
        resource = Resource(attributes=metric_resource_attributes)
        metrics_exporter = AzureMonitorMetricExporter(connection_string=self.conn_string)
        metrics_reader = PeriodicExportingMetricReader(metrics_exporter)
        metrics_provider = MeterProvider(resource=resource, metric_readers=[metrics_reader])
        metrics.set_meter_provider(metrics_provider)
        meter = metrics.get_meter_provider().get_meter(name=metric_name, version=metric_version)

        return meter
