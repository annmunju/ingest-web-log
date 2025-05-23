# consumer_store.py
import json
import os
from pathlib import Path
from confluent_kafka import Consumer, KafkaError

# Kafka 설정
KAFKA_BOOTSTRAP = os.getenv("BOOTSTRAP_SERVERS", "localhost:9092")
KAFKA_TOPIC = os.getenv("KAFKA_TOPIC", "clickstream")

# 출력 경로 설정
OUTPUT_DIR = Path("output")
OUTPUT_DIR.mkdir(exist_ok=True)
OUTPUT_FILE = OUTPUT_DIR / "clickstream_output.jsonl"

# Kafka Consumer 설정
consumer_conf = {
    "bootstrap.servers": KAFKA_BOOTSTRAP,
    "group.id": "clickstream-consumer-group",
    "auto.offset.reset": "earliest",
}

consumer = Consumer(consumer_conf)
consumer.subscribe([KAFKA_TOPIC])

print(f"Consuming from topic '{KAFKA_TOPIC}'...")

try:
    with open(OUTPUT_FILE, "a", encoding="utf-8") as f:
        while True:
            msg = consumer.poll(1.0)
            if msg is None:
                continue
            if msg.error():
                if msg.error().code() != KafkaError._PARTITION_EOF:
                    print("Error:", msg.error())
                continue

            payload = msg.value().decode("utf-8")
            print("Received:", payload)
            f.write(payload + "\n")

except KeyboardInterrupt:
    print("Stopped by user.")

finally:
    consumer.close()