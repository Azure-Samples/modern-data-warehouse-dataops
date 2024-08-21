import os
from datetime import datetime
import logging

from opentelemetry.sdk.resources import SERVICE_NAME, Resource
from opentelemetry.trace.status import StatusCode  
from opentelemetry.trace import SpanKind

# Logs
from opentelemetry._logs import set_logger_provider
from opentelemetry.sdk._logs import LoggerProvider, LoggingHandler
from opentelemetry.sdk._logs.export import BatchLogRecordProcessor

# Traces
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import (
    BatchSpanProcessor, 
    ConsoleSpanExporter)

# Metrics
from opentelemetry import metrics
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader

# NOTE we are manually passing the endpoint when reating OTLP*Exporter; this could be also read from environment variable: OTEL_EXPORTER_OTLP_ENDPOINT.
# for example
#   if OTEL_EXPORTER_OTLP_ENDPOINT is set in env, then: exporter = OTLPSpanExporter()
#   if OTEL_EXPORTER_OTLP_ENDPOINT is NOT set in env, then: exporter = OTLPSpanExporter(endpoint=<your end point>)
# See: https://opentelemetry.io/docs/specs/otel/protocol/exporter/#configuration-options for setting evironment variables.
# Python configuration: https://opentelemetry.io/docs/zero-code/python/configuration/

logging.basicConfig(level=logging.INFO)  # we don't set this here it is not displaying info level

class OpenTelemetryExporter:  
    def __init__(self, port_type: str, otel_collector_ip: str):  
        """  
        Initializes the OpenTelemetryExporter class.  
  
        Args:  
            port_type (str): The type of port to use for communication ("http" or "grpc").  
            otel_collector_ip (str): The IP address of the OpenTelemetry collector.  
            resource_attributes (dict): The OpenTelemetry resource attributes in dictionary format 
        """  

        global OTLPSpanExporter, OTLPMetricExporter, OTLPLogExporter

        self.port_type = port_type  
        self.otel_collector_ip = otel_collector_ip  

        # see endpoint configuration: https://opentelemetry.io/docs/specs/otel/protocol/exporter/#configuration-options
        if self.port_type == "http":  
            self.http_port = "4318"  
            self.otlp_end_point = f"http://{self.otel_collector_ip}:{self.http_port}"  
            self.traces_end_point = f"{self.otlp_end_point}/v1/traces"  
            self.logs_end_point = f"{self.otlp_end_point}/v1/logs"  
            self.metrics_end_point = f"{self.otlp_end_point}/v1/metrics" 
            from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter   
            from opentelemetry.exporter.otlp.proto.http.metric_exporter import OTLPMetricExporter  
            from opentelemetry.exporter.otlp.proto.http._log_exporter import OTLPLogExporter  
        elif self.port_type == "grpc":  
            self.grpc_port = "4317"  
            self.otlp_end_point = f"http://{self.otel_collector_ip}:{self.grpc_port}"    
            self.metrics_end_point = self.logs_end_point = self.traces_end_point = self.otlp_end_point  
            from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter  
            from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter  
            from opentelemetry.exporter.otlp.proto.grpc._log_exporter import OTLPLogExporter 
        else:
            raise ValueError("Invalid port type {self.port_type} - allowed values are 'http' or 'grpc'")


    def get_otel_tracer(self, trace_resource_attributes: dict, tracer_name: str = __name__):
        """  
        Creates and returns an OpenTelemetry tracer object. 
  
        Args:  
            trace_resource_attributes (dict): The OpenTelemetry resource attributes in dictionary format  
            tracer_name (str): The name of the tracer. Default is __name__.
        Returns:
            tracer: OpenTelemetry tracer object
        """  
        resource = Resource(attributes=trace_resource_attributes)
        traceProvider = TracerProvider(resource=resource) 
        otlp_exporter = OTLPSpanExporter(
            endpoint=self.traces_end_point,
            # credentials=ChannelCredentials(credentials),
            # headers=(("metadata", "metadata")),
        )
        processor = BatchSpanProcessor(otlp_exporter)
        traceProvider.add_span_processor(processor)
        trace.set_tracer_provider(traceProvider)

        # # write to console
        # console_processor = BatchSpanProcessor(ConsoleSpanExporter())
        # traceProvider.add_span_processor(console_processor)

        tracer = trace.get_tracer(tracer_name)

        return tracer


    def get_otel_logger(self, log_resource_attributes: dict, logger_name: str = __name__, add_console_handler: bool = True):
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
        logger_provider = LoggerProvider(resource=resource) 
        # set_logger_provider(logger_provider)
        log_exporter = OTLPLogExporter(
            endpoint= self.logs_end_point, # os.getenv('OTEL_EXPORTER_OTLP_ENDPOINT')
            )
        logger_provider.add_log_record_processor(BatchLogRecordProcessor(log_exporter))
        handler = LoggingHandler(level=logging.INFO, logger_provider=logger_provider) 
        logging.getLogger().addHandler(handler) # Attach OTLP handler to root logger

        logger = logging.getLogger(logger_name) # get namespaced logger

        # # Create a console handler  - Optional
        if add_console_handler:
            console_handler = logging.StreamHandler()  
            console_handler.setLevel(logging.INFO)  
            logger.addHandler(console_handler)  

        return logger


    def get_otel_metrics(self, metric_resource_attributes: dict, metric_name: str = __name__, metric_version: str = "0"):
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
        metrics_exporter = OTLPMetricExporter(
            endpoint=self.metrics_end_point
            )
        metrics_reader = PeriodicExportingMetricReader(metrics_exporter)
        metrics_provider = MeterProvider(resource=resource, metric_readers=[metrics_reader])
        metrics.set_meter_provider(metrics_provider)
        meter = metrics.get_meter_provider().get_meter(name=metric_name, version=metric_version)

        return meter
