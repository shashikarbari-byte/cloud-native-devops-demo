"""Small Flask service used as the workload for the DevOps pipeline in this repo."""
import os
import time

from flask import Flask, Response, jsonify, request
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest

app = Flask(__name__)

REQUESTS = Counter(
    "http_requests_total", "Total HTTP requests", ["method", "endpoint", "status"]
)
LATENCY = Histogram(
    "http_request_duration_seconds", "HTTP request latency in seconds", ["endpoint"]
)


@app.before_request
def _start_timer():
    request._started = time.perf_counter()


@app.after_request
def _record_metrics(response):
    endpoint = request.path
    if endpoint != "/metrics":
        elapsed = time.perf_counter() - getattr(request, "_started", time.perf_counter())
        LATENCY.labels(endpoint).observe(elapsed)
        REQUESTS.labels(request.method, endpoint, response.status_code).inc()
    return response


@app.get("/")
def index():
    return jsonify(
        message="Hello from the cloud-native DevOps demo",
        version=os.getenv("APP_VERSION", "dev"),
        environment=os.getenv("APP_ENV", "local"),
    )


@app.get("/healthz")
def healthz():
    """Liveness probe."""
    return jsonify(status="ok")


@app.get("/readyz")
def readyz():
    """Readiness probe."""
    return jsonify(status="ready")


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "8080")))
