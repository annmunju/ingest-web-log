# Dockerfile (운영용)
FROM python:3.9-slim

# 1) 시스템 패키지
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential python3-dev librdkafka-dev ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# 2) RIC(런타임 인터페이스 클라이언트) + 앱 deps 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt awslambdaric

# 3) 앱 복사
COPY ingest_kafka.py .

# 4) ENTRYPOINT/CMD 설정
ENTRYPOINT ["python3", "-m", "awslambdaric"]
CMD ["ingest_kafka.handler"]