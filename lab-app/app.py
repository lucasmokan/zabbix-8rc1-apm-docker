import logging
import os
import random
import time

from opentelemetry import metrics, trace
from opentelemetry.exporter.otlp.proto.grpc._log_exporter import OTLPLogExporter
from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.metrics import Observation
from opentelemetry.sdk._logs import LoggerProvider, LoggingHandler
from opentelemetry.sdk._logs.export import BatchLogRecordProcessor
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.trace import Status, StatusCode

ENDPOINT = os.getenv("OTLP_ENDPOINT", "zabbix-proxy:4317")
SERVICE = os.getenv("SERVICE_NAME", "lab-app")
INTERVAL = float(os.getenv("REQUEST_INTERVAL", "0.5"))
START = time.time()

resource = Resource.create({"service.name": SERVICE})

tp = TracerProvider(resource=resource)
tp.add_span_processor(BatchSpanProcessor(OTLPSpanExporter(endpoint=ENDPOINT, insecure=True)))
trace.set_tracer_provider(tp)
tracer = trace.get_tracer("lab-app")

reader = PeriodicExportingMetricReader(
    OTLPMetricExporter(endpoint=ENDPOINT, insecure=True), export_interval_millis=10000
)
metrics.set_meter_provider(MeterProvider(resource=resource, metric_readers=[reader]))
meter = metrics.get_meter("lab-app")
meter.create_observable_gauge(
    "system.uptime", callbacks=[lambda o: [Observation(time.time() - START)]], unit="s"
)
requests_total = meter.create_counter("app.requests", unit="1")
latency = meter.create_histogram("app.request.duration", unit="ms")

lp = LoggerProvider(resource=resource)
lp.add_log_record_processor(BatchLogRecordProcessor(OTLPLogExporter(endpoint=ENDPOINT, insecure=True)))
log = logging.getLogger("lab-app")
log.setLevel(logging.DEBUG)
log.addHandler(LoggingHandler(level=logging.DEBUG, logger_provider=lp))
log.addHandler(logging.StreamHandler())


def handle_request():
    roll = random.random()
    with tracer.start_as_current_span("GET /pedido", kind=trace.SpanKind.SERVER) as span:
        t0 = time.time()
        with tracer.start_as_current_span("SELECT pedidos", kind=trace.SpanKind.CLIENT):
            time.sleep(random.uniform(0.005, 0.05))
        time.sleep(random.uniform(0.01, 0.2))
        if roll < 0.80:
            span.set_status(Status(StatusCode.OK))
            log.info("pedido processado")
            outcome = "ok"
        elif roll < 0.92:
            span.set_status(Status(StatusCode.ERROR, "falha ao processar"))
            log.error("erro ao processar pedido")
            outcome = "error"
        elif roll < 0.97:
            log.warning("pedido lento")
            outcome = "unset"
        else:
            span.set_status(Status(StatusCode.ERROR, "falha critica"))
            log.critical("banco de dados indisponivel")
            outcome = "fatal"
        requests_total.add(1, {"outcome": outcome})
        latency.record((time.time() - t0) * 1000, {"outcome": outcome})


if __name__ == "__main__":
    log.info("iniciando %s, enviando para %s", SERVICE, ENDPOINT)
    while True:
        handle_request()
        time.sleep(INTERVAL)
