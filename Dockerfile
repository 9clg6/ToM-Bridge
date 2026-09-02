# =============================================================================
# ToM Bridge — production image
#
# Usage:
#   docker build -t tom-bridge .
#   docker run --rm tom-bridge -c /app/config.yaml [-f /app/registration.yaml]
#
# The compiled binary accepts any of the matrix-appservice-bridge CLI flags
# (e.g. -c/--config, -f for registration override, -p for port).
# =============================================================================

# -----------------------------------------------------------------------------
# Stage 1 — builder: compile SRD into a standalone binary with bunup
# -----------------------------------------------------------------------------
FROM docker.io/oven/bun:debian AS builder

WORKDIR /app

# Install dependencies (patches/ is required by patchedDependencies)
COPY package.json bun.lock bunup.config.ts tsconfig.json ./
COPY patches/ ./patches/
COPY src/ ./src/

RUN ls -R

RUN bun install --frozen-lockfile

# Compile single-file executable — output is ./bin/tom-bridge
RUN bunx bunup

# -----------------------------------------------------------------------------
# Stage 2 — runtime: fresh slim Debian image with just the binary
# -----------------------------------------------------------------------------
FROM docker.io/debian:stable-slim AS runtime

# ca-certificates for outbound HTTPS (Matrix homeserver, avatar uploads)
ENV DEBIAN_FRONTEND=noninteractive
RUN apt update \
    && apt install -yqq --no-install-recommends --no-install-suggests ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY package.json ./
COPY --from=builder /app/bin/tom-bridge ./

ENV REGISTRATION_FILE=/app/registration.yaml

ENTRYPOINT ["./tom-bridge", "-c", "/app/config.yaml"]
