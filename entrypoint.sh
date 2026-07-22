#!/bin/bash
# Default fallbacks if Pterodactyl variables are somehow missing
export DMB_FILENAME="${DMB_FILENAME:-game}"
export SERVER_PORT="${SERVER_PORT:-2506}"
export ADDITIONAL_FLAGS="${ADDITIONAL_FLAGS:-}"

# Change to the server files directory
cd /home/container

# Execute DreamDaemon dynamically using the environment variables
exec DreamDaemon "${DMB_FILENAME}.dmb" "${SERVER_PORT}" -trusted "${ADDITIONAL_FLAGS}"
