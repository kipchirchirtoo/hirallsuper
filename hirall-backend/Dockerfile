# ---------------------------------------------------
# Multi-stage Docker build for hirall-backend
# ---------------------------------------------------
FROM rust:1.80-alpine AS builder

RUN apk add --no-cache musl-dev pkgconfig openssl-dev

WORKDIR /app

# Cache dependency builds
COPY Cargo.toml ./
RUN mkdir src && echo "fn main() {}" > src/main.rs
RUN cargo build --release || true

# Copy real sources and migrations
COPY src ./src
COPY migrations ./migrations

# Build the real binary
RUN touch src/main.rs && cargo build --release

# ---------------------------------------------------
# Runtime image
# ---------------------------------------------------
FROM alpine:3.20

RUN apk add --no-cache ca-certificates tzdata libgcc

WORKDIR /app

COPY --from=builder /app/target/release/hirall-backend /app/hirall-backend
COPY --from=builder /app/migrations /app/migrations
COPY .env.example /app/.env

EXPOSE 8080

CMD ["/app/hirall-backend"]
