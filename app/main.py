import logging
import os
import time

from fastapi import FastAPI, Request

APP_ENV = os.getenv("APP_ENV", "dev")
APP_VERSION = os.getenv("APP_VERSION", "0.1.0")
APP_SERVICE_NAME = os.getenv("APP_SERVICE_NAME", "fastapi-showcase")
APP_PORT = int(os.getenv("APP_PORT", "8000"))

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)

app = FastAPI(title=APP_SERVICE_NAME, version=APP_VERSION)


@app.middleware("http")
async def request_logging_middleware(request: Request, call_next):
    start_time = time.perf_counter()
    response = await call_next(request)
    duration_ms = (time.perf_counter() - start_time) * 1000
    logger.info(
        "env=%s version=%s method=%s path=%s status=%s duration_ms=%.2f",
        APP_ENV,
        APP_VERSION,
        request.method,
        request.url.path,
        response.status_code,
        duration_ms,
    )
    return response


@app.get("/")
def root():
    return {"service": APP_SERVICE_NAME, "env": APP_ENV, "version": APP_VERSION}


@app.get("/health")
def health():
    return {"status": "ok", "env": APP_ENV, "version": APP_VERSION}


@app.get("/version")
def version():
    return {"env": APP_ENV, "version": APP_VERSION}
