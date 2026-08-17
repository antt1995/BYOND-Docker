# ========================================================
# STAGE 1: Build 32-bit rust-g from source
# ========================================================
FROM debian:bookworm-slim AS rust_builder

ENV DEBIAN_FRONTEND=noninteractive

# Install 32-bit cross-compilation packages and build tools
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        git \
        make \
        gcc-multilib \
        g++-multilib \
        pkg-config \
        libstdc++6:i386 \
        libssl-dev:i386 \
        libssl3:i386 \
        libcurl4:i386 \
        zlib1g:i386 \
        ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Rust toolchain with the 32-bit Linux target
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
RUN rustup target add i686-unknown-linux-gnu

# Clone and compile the official tgstation rust-g library
# Note: Pin a specific tag/version here if your codebase requires an older release

RUN git clone --depth 1 https://github.com/tgstation/rust-g /build/rust-g && \
    cd /build/rust-g && \
    PKG_CONFIG_ALLOW_CROSS=1 \
    OPENSSL_DIR=/usr \
    cargo build --release --target i686-unknown-linux-gnu


# ==========================================
# STAGE 2: Lean Final BYOND Server Runtime
# ==========================================
FROM debian:bookworm-slim

LABEL author="antt1995" maintainer="antt1995"
ENV DEBIAN_FRONTEND=noninteractive

# Runtime dependencies (includes ssl & zlib for rust-g HTTP functions)
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        unzip \
        make \
        ca-certificates \
        libstdc++6:i386 \
        libssl-dev:i386 \
        libssl3:i386 \
        zlib1g:i386 \
        libcurl4:i386 \
        git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install BYOND Engine
ENV BYOND_VERSION=516.1686

RUN BYOND_MAJOR="${BYOND_VERSION%%.*}" \
    && curl "https://byond-builds.dm-lang.org/${BYOND_MAJOR}/${BYOND_VERSION}_byond_linux.zip" -o byond.zip \
    && unzip byond.zip \
    && cd byond \
    && make install \
    && cd .. \
    && rm -rf byond.zip byond

# Create globally accessible directory for our pre-baked library
RUN mkdir -p /opt/tgstation/lib/

# Copy the compiled 32-bit .so file from the builder stage
COPY --from=rust_builder /build/rust-g/target/i686-unknown-linux-gnu/release/librust_g.so /opt/tgstation/lib/librust_g.so


# Recreate the exact Pterodactyl container user sandbox
RUN useradd -d /home/container -m container

USER container

ENV USER=container HOME=/home/container
WORKDIR /home/container

COPY ./entrypoint.sh /entrypoint.sh
CMD ["/bin/bash", "/entrypoint.sh"]
