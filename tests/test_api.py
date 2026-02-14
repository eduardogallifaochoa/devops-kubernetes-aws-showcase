from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_health_endpoint():
    response = client.get("/health")
    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] == "ok"
    assert "env" in payload
    assert "version" in payload


def test_version_endpoint():
    response = client.get("/version")
    assert response.status_code == 200
    payload = response.json()
    assert "env" in payload
    assert "version" in payload


def test_root_endpoint():
    response = client.get("/")
    assert response.status_code == 200
    payload = response.json()
    assert payload["service"] == "fastapi-showcase"
    assert "env" in payload
    assert "version" in payload
