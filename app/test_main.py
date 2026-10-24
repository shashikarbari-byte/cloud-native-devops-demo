from main import app


def client():
    return app.test_client()


def test_index():
    resp = client().get("/")
    assert resp.status_code == 200
    assert "message" in resp.get_json()


def test_health_endpoints():
    assert client().get("/healthz").get_json() == {"status": "ok"}
    assert client().get("/readyz").get_json() == {"status": "ready"}


def test_metrics_exposed():
    client().get("/")
    resp = client().get("/metrics")
    assert resp.status_code == 200
    assert b"http_requests_total" in resp.data
