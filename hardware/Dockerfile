FROM archlinux:latest

WORKDIR /app

# Install nodejs, npm and neofetch from official repos
RUN pacman -Sy --noconfirm base-devel nodejs npm python3 fastfetch

COPY package.json package-lock.json ./

RUN npm install

COPY rl-websocket.js ./

ARG API_KEY
ENV API_KEY=${API_KEY}

CMD ["node", "rl-websocket.js"]

EXPOSE 1906