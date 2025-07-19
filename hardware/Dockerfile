FROM node

WORKDIR /app
COPY package.json package-lock.json ./
COPY package.json package-lock.json ./
COPY package.json package-lock.json ./

RUN npm install

# Install neofetch
RUN apt-get update && apt-get install -y neofetch && rm -rf /var/lib/apt/lists/*

COPY rl-websocket.js ./

ARG API_KEY
ENV API_KEY=${API_KEY}

CMD ["node", "rl-websocket.js"]

EXPOSE 1906