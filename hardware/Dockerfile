FROM --platform=linux/amd64 ubuntu:22.04

ARG API_KEY
ENV API_KEY=${API_KEY}

# Install CA certificates for HTTPS requests
RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY dist/rl-websocket/ ./

CMD ["./rl-websocket", "hardware-example-1", "123.213.123", "hardware-example", "1906"]

EXPOSE 1906