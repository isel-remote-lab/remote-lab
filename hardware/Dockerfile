FROM ubuntu:22.04

ARG API_KEY
ENV API_KEY=${API_KEY}

COPY dist/rl-websocket/rl-websocket /usr/local/bin/rl-websocket

CMD ["rl-websocket", "hardware-example", "0", "6000"]