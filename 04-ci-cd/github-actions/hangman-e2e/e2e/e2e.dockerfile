FROM cypress/base:16

WORKDIR /app

COPY package.json .

COPY package-lock.json .

RUN npm ci

COPY . .

ENV CI=1

RUN npx cypress verify

CMD ["npx", "cypress", "run"]
