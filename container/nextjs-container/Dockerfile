FROM node:20-bookworm

ENV TZ='Asia/Tokyo'
ENV NODE_ENV="production"

COPY . /app

WORKDIR /app

RUN \
  npm ci --include=dev && \
  npm run build

# ----------------------------
# run server
# ----------------------------

FROM node:20-bookworm

ENV TZ='Asia/Tokyo'
ENV NODE_ENV="production"

COPY --from=0 /app/package.json /app/package.json
COPY --from=0 /app/package-lock.json /app/package-lock.json
COPY --from=0 /app/.next /app/.next
COPY --from=0 /app/public /app/public 
COPY --from=0 /app/next.config.js /app/next.config.js


WORKDIR /app


RUN \
  apt-get update && \
  apt-get install -y tini && \
  npm ci --omit=dev && \
  npx next telemetry disable

EXPOSE 3000

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/app/node_modules/.bin/next", "start"]
