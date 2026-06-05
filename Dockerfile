FROM oven/bun:1.3.10-slim

ENV NODE_ENV=production
ENV GBRAIN_HOME=/data/.gbrain
ENV PORT=3131
ENV PUBLIC_URL=http://localhost:3131

WORKDIR /app

COPY package.json bun.lock ./
RUN bun install --frozen-lockfile

COPY . .

RUN mkdir -p /data/.gbrain

EXPOSE 3131

CMD ["sh", "-c", "bun run src/cli.ts serve --http --port ${PORT:-3131} --bind 0.0.0.0 --public-url ${PUBLIC_URL:-http://localhost:3131}"]
