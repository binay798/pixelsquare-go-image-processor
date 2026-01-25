# --- STAGE 1: Build Stage ---
FROM golang:1.25-bookworm AS builder

# 1. Install build dependencies for Cgo and libvips
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    pkg-config \
    libvips-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 2. Cache Go modules
COPY go.mod go.sum ./
RUN go mod download

# 3. Copy source and build
COPY . .
# We must enable CGO because bimg requires it
RUN CGO_ENABLED=1 GOOS=linux go build -o main .

# --- STAGE 2: Final Runtime Stage ---
FROM debian:bookworm-slim

# 4. Install ONLY the runtime shared libraries for vips (no compilers)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libvips42 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /root/

# 5. Copy the binary from the builder stage
COPY --from=builder /app/main .


# Expose the port your Fiber app is listening on
EXPOSE 8849

# Run the application
CMD ["./main"]