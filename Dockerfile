# =============================================================================
# ToM Bridge - production image
#
# Usage:
#   docker build -t tom-bridge .
#   docker run
#       -v /path/to/config.yaml:/data/config.yaml:ro
#       -v /path/to/registration.yaml:/data/registration.yaml:ro
#       --rm tom-bridge
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1 - builder: compile into a standalone binary with bunup
# -----------------------------------------------------------------------------
FROM docker.io/oven/bun:debian AS builder

WORKDIR /app

COPY package.json bun.lock bunup.config.ts tsconfig.json ./
COPY patches/ ./patches/
COPY src/ ./src/

RUN bun install --frozen-lockfile

RUN bunx bunup

# -----------------------------------------------------------------------------
# Stage 2 - runtime image: fresh with assets files and binary only
# -----------------------------------------------------------------------------
FROM docker.io/debian:stable-slim AS runtime

WORKDIR /app
RUN mkdir -p /data

COPY package.json ./
COPY --from=builder /app/bin/tom-bridge ./

ENV REGISTRATION_FILE=/data/registration.yaml

ENTRYPOINT ["./tom-bridge", "-c", "/data/config.yaml"]
