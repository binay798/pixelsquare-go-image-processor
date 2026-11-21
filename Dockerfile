# --- STAGE 1: Build ---
FROM golang:1.25-bookworm AS builder

# bimg is a cgo binding, so a C toolchain and the libvips headers are required to compile.
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    pkg-config \
    libvips-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src

# Download modules first so this layer stays cached while only the source changes.
COPY go.mod go.sum ./
RUN go mod download

# Build the project.
COPY . .
RUN CGO_ENABLED=1 GOOS=linux go build \
    -trimpath \
    -ldflags="-s -w" \
    -o /out/main .

# --- STAGE 2: Runtime ---
FROM debian:bookworm-slim

# Only the libvips shared libraries are needed at runtime (no compiler/headers).
RUN apt-get update && apt-get install -y --no-install-recommends \
    libvips42 \
    ca-certificates \
    tzdata \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --system --gid 10001 app \
    && useradd --system --uid 10001 --gid app --home-dir /app --shell /usr/sbin/nologin app

WORKDIR /app

# Copy the binary produced by the build stage.
COPY --from=builder --chown=app:app /out/main ./main

# Mount point for the env file injected by the Kubernetes deployment
# (see kube-config/img-compressor/deployment.yml).
RUN mkdir -p /app/secrets && chown app:app /app/secrets

# Defaults so the image can also run standalone (docker run / docker compose).
# NOTE: godotenv.Load() in main.go never overrides variables that are already set,
# so these image defaults take precedence over the mounted /app/secrets/.env file.
ENV APP_HOST=0.0.0.0 \
    APP_PORT=8849

USER app
EXPOSE 8849

# Run the built app.
CMD ["./main"]
