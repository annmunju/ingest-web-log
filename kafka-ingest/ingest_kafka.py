# ingest_kafka.py
import os
import json
import logging
from typing import Optional
from pydantic import BaseModel
from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from confluent_kafka import Producer, KafkaException

# ———— 로거 설정 ————
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("ingest")

# ———— 환경변수 로드 ————
KAFKA_BOOTSTRAP = os.getenv("BOOTSTRAP_SERVERS", "localhost:9092")
KAFKA_TOPIC     = os.getenv("KAFKA_TOPIC", "clickstream")
APP_PORT        = int(os.getenv("APP_PORT", 8000))

# ———— FastAPI 앱 생성 ————
app = FastAPI(title="Clickstream Ingest API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# ———— Kafka 프로듀서 싱글톤 ————
producer = Producer({"bootstrap.servers": KAFKA_BOOTSTRAP})


@app.post("/ingest")
async def ingest(request: Request):
    """
    클라이언트로부터 들어온 JSON을 검증 없이 그대로 Kafka로 전송합니다.
    """
    try:
        evt = await request.json()
    except Exception as e:
        logger.error(f"Invalid JSON payload: {e}")
        raise HTTPException(status_code=400, detail="Invalid JSON")

    try:
        producer.produce(KAFKA_TOPIC, json.dumps(evt).encode("utf-8"))
        producer.flush()
        logger.info(f"Produced to {KAFKA_TOPIC}: {evt}")
    except KafkaException as e:
        logger.error(f"Kafka produce error: {e}")
        raise HTTPException(status_code=500, detail="Failed to enqueue event")

    return {"status": "ok", "topic": KAFKA_TOPIC, "received": evt}
# ———— 앱 실행 예시 ————
# uvicorn ingest_kafka:app --reload --port 8000