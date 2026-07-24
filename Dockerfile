# ==========================================
# STAGE 1: Compile rust-g with HTTP features
# ==========================================
FROM i386/debian:bookworm-slim AS builder

# Install system dependencies required to compile Rust libraries
RUN apt-get update && apt-get install -y \
    curl \
    git \
    gcc \
    g++ \
    make \
    pkg-config \
    libssl-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Install the 32-bit Rust toolchain matching the container architecture
RUN curl --proto '=https' --tlsv1.2 -sSf https://rustup.rs | sh -s -- -y --default-host i686-unknown-linux-gnu
ENV PATH="/root/.cargo/bin:${PATH}"

# Clone the repository and compile the library with the mandatory http feature flags
WORKDIR /build
RUN git clone https://github.com . \
    && cargo build --release --features "http"


# ==========================================
# STAGE 2: Lean Final BYOND Server Runtime
# ==========================================
FROM i386/debian:bookworm-slim

ENV BYOND_MAJOR=516 \
    BYOND_MINOR=1685

ENV LD_LIBRARY_PATH="/home/byond/BYOND/lib:${LD_LIBRARY_PATH}"

# Runtime dependencies (includes ssl & zlib for rust-g HTTP functions)
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    make \
    libstdc++6 \
    zlib1g \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

# Install BYOND (Kept from your original Dockerfile)
WORKDIR /home/byond
RUN curl "https://byond-builds.dm-lang.org/${BYOND_MAJOR}/${BYOND_MAJOR}.${BYOND_MINOR}_byond_linux.zip" -o byond.zip \
    && unzip byond.zip \
    && cd byond \
    && make install \
    && cd .. \
    && rm -rf byond.zip BYOND

# CRITICAL STEP: Copy only the freshly built librustg.so from Stage 1 into the server environment
# (Change '/usr/local/lib/' to wherever your game maps its external library files, if different)
COPY --from=builder /build/target/release/librustg.so /usr/local/lib/librustg.so

# Recreate the exact Pterodactyl container user sandbox
RUN useradd -d /home/container -m container

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

# Wipe out rigid image entrypoints to fix Group ID errors permanently
ENTRYPOINT ["/entrypoint.sh"]