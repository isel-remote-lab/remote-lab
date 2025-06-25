FROM python:3.10-slim

RUN python3 -m pip install websockets requests

ARG API_KEY
ENV API_KEY=${API_KEY}

WORKDIR /app

COPY rl-websocket.py ./

CMD ["python3", "rl-websocket.py", "hardware-example-1", "123.213.123", "localhost", "1906"]

EXPOSE 1906