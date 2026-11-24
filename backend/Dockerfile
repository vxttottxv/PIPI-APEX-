FROM python:3.11-slim

WORKDIR /app

# 기본 환경 변수
ENV HOST=0.0.0.0 \
    PORT=3000 \
    PYTHONUNBUFFERED=1

# 의존성 설치
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt

# 소스 코드 복사
COPY server.py ./

# 데이터 저장 볼륨
VOLUME ["/app/data"]
ENV DB_PATH=/app/data/pipi.db

EXPOSE 3000

CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "3000"]
