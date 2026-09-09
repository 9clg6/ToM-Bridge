# =============================================================================
# ToM Bridge - production image
#
# Usage:
#   docker build -t tom-bridge .
#   docker run
#       -v /path/to/config.yaml:/app/config.yaml:ro
#       -v /path/to/registration.yaml:/app/registration.yaml:ro
#       -e REGISTRATION_FILE=/app/registration.yaml
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

COPY package.json ./
COPY --from=builder /app/bin/tom-bridge ./

ENV REGISTRATION_FILE=/app/registration.yaml

ENTRYPOINT ["./tom-bridge", "-c", "/app/config.yaml"]
