FROM i386/debian:bookworm-slim

# Install necessary build and runtime dependencies for BYOND
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    make \
    build-essential \
    libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

# Configured directly for BYOND version 516.1685
ENV BYOND_MAJOR=516 \
    BYOND_MINOR=1685

# Download, extract, and globally install BYOND 
RUN curl -o byond.zip "https://byond-builds.dm-lang.org/${BYOND_MAJOR}/${BYOND_MAJOR}.${BYOND_MINOR}_byond_linux.zip" \
    && unzip byond.zip \
    && cd byond \
    && make install \
    && cd .. \
    && rm -rf byond byond.zip

# Recreate the exact Pterodactyl container user sandbox
RUN useradd -d /home/container -m container

USER container
ENV USER=container HOME=/home/container
WORKDIR /home/container

# Wipe out rigid image entrypoints to fix Group ID errors permanently
ENTRYPOINT []
CMD ["/bin/bash"]
