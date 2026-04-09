FROM rust:1.70 as builder

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    pkg-config \
    libssl-dev \
    git \
    curl \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /chameleon-zk

# Copy project files
COPY prover prover/
COPY circuits circuits/
COPY contracts contracts/
COPY scripts scripts/

# Build prover
WORKDIR /chameleon-zk/prover
RUN cargo build --release

# Runtime image
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    libssl3 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy built binary
COPY --from=builder /chameleon-zk/prover/target/release/chameleon-prover /usr/local/bin/
COPY --from=builder /chameleon-zk/scripts /app/scripts

ENV PATH="/app/scripts:${PATH}"

CMD ["chameleon-prover", "--help"]
