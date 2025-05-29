# ingest_kafka.py
import os
import json
import logging
from typing import Any, Dict, Optional

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from confluent_kafka import Producer, KafkaException
from mangum import Mangum

# ———— 로거 설정 ————
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("ingest_kafka")

# ———— 환경변수 로드 ————
KAFKA_BOOTSTRAP = os.getenv("BOOTSTRAP_SERVERS", "localhost:9092")
KAFKA_TOPIC     = os.getenv("KAFKA_TOPIC", "clickstream")

# ———— FastAPI 앱 생성 ————
app = FastAPI(
    title="Clickstream Ingest API",
    version="1.0.0",
    description="API to ingest clickstream events into Kafka"
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["POST"],
    allow_headers=["*"],
)

# ———— Kafka 프로듀서 싱글톤 ————
producer = Producer({"bootstrap.servers": KAFKA_BOOTSTRAP})

# ———— Pydantic 모델 정의 ————
class ClickEvent(BaseModel):
    event: str
    timestamp: str
    path: Optional[str] = None
    referrer: Optional[str] = None
    utm_source: Optional[str] = None
    utm_medium: Optional[str] = None
    utm_campaign: Optional[str] = None
    properties: Dict[str, Any] = {}

@app.post("/ingest", status_code=200)
async def ingest(event: ClickEvent):
    """
    Kafka에 ClickEvent를 전송합니다.
    """
    try:
        payload = event.json().encode("utf-8")
        producer.produce(KAFKA_TOPIC, payload)
        producer.flush()
        logger.info(f"Produced to topic {KAFKA_TOPIC}: {payload}")
    except KafkaException as e:
        logger.error(f"Kafka produce error: {e}")
        raise HTTPException(status_code=500, detail="Failed to enqueue event")

    return {
        "status": "ok",
        "topic": KAFKA_TOPIC,
        "data": event.dict()
    }

# ———— AWS Lambda 핸들러 ————
handler = Mangum(app)
