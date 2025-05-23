# Kafka Ingest API

이 프로젝트는 FastAPI로 구현된 Kafka 프로듀서 역할의 API입니다. 이 API는 클라이언트로부터 JSON 데이터를 받아 Kafka로 전송합니다. 이 README에서는 프로젝트를 설정하고 실행하는 방법을 설명합니다.

## 요구 사항

이 프로젝트를 실행하기 위해 필요한 패키지는 `requirements.txt`에 명시되어 있습니다. 다음 명령어로 필요한 패키지를 설치할 수 있습니다.
```bash
pip install -r requirements.txt
```

## Docker Compose 설정

이 프로젝트는 Kafka와 Zookeeper를 포함하는 Docker Compose 파일을 제공합니다. `docker-compose.yml` 파일을 사용하여 카프카 클러스터를 쉽게 설정할 수 있습니다.

### 1. 카프카 클러스터 띄우기

다음 명령어를 사용하여 카프카와 Zookeeper를 실행합니다.

```bash
docker-compose up -d
```

### 2. 토픽 만들기

카프카 클러스터가 실행 중인 상태에서, 다음 명령어를 사용하여 필요한 토픽을 생성합니다. 여기서는 `clickstream`이라는 토픽을 생성합니다.

```bash
docker exec -it <kafka_container_name> kafka-topics --create --topic clickstream --bootstrap-server localhost:9092 --replication-factor 1 --partitions 1
```
`<kafka_container_name>`은 실행 중인 Kafka 컨테이너의 이름으로 대체해야 합니다.

### 3. FastAPI 실행하기

FastAPI 애플리케이션을 실행하려면 다음 명령어를 사용합니다.
```bash
uvicorn ingest_kafka:app --reload --port 8000
```

이제 FastAPI가 실행되며, 클라이언트로부터 JSON 데이터를 수신할 준비가 완료되었습니다.

## API 사용법

`POST /ingest` 엔드포인트를 통해 JSON 데이터를 Kafka로 전송할 수 있습니다. 요청 예시는 다음과 같습니다.
```json
{
  "key": "value"
}
```

응답은 다음과 같은 형식으로 반환됩니다.
```json
{
  "status": "ok",
  "topic": "clickstream",
  "received": {
    "key": "value"
  }
}
```


## 결론

이 프로젝트는 FastAPI와 Kafka를 통합하여 실시간 데이터 스트리밍을 가능하게 합니다. 필요한 모든 설정과 실행 방법이 이 README에 포함되어 있으니, 이를 참고하여 프로젝트를 실행해 보시기 바랍니다.