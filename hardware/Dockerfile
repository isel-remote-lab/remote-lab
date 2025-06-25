FROM node

WORKDIR /app
COPY package.json ./

RUN npm install

COPY rl-websocket.js ./

ARG API_KEY
ENV API_KEY=${API_KEY}

CMD ["node", "rl-websocket.js"]

EXPOSE 1906