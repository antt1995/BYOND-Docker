#!/bin/bash
# Default fallbacks if Pterodactyl variables are somehow missing
export DMB_FILENAME="${DMB_FILENAME:-game}"
export SERVER_PORT="${SERVER_PORT:-2506}"
export ADDITIONAL_FLAGS="${ADDITIONAL_FLAGS:-}"

# Change to the server files directory
cd /home/container

echo "Ensuring file permissions are synchronized..."
chmod -R 755 . 2>/dev/null || true

echo "--------------------------------------------------------"
echo "Starting BYOND Server via Generic Architecture"
echo "Target Binaries : ${DMB_FILENAME}.dmb / ${DMB_FILENAME}.rsc"
echo "Network Port    : ${SERVER_PORT}"
echo "Active Version  : $(DreamDaemon -version | head -n 1)"
echo "--------------------------------------------------------"

# Execute DreamDaemon dynamically using the environment variables
exec DreamDaemon "${DMB_FILENAME}.dmb" "${SERVER_PORT}" -trusted "${ADDITIONAL_FLAGS}"

# Capture the exit code of BYOND
EXIT_CODE=$?

# If the game closed cleanly or your codebase wiped the shutdown file, 
# force a clean 0 exit code so Pterodactyl knows it was intentional.
if [ ! -f "shutdown.txt" ] || [ $EXIT_CODE -eq 0 ]; then
    echo "BYOND closed cleanly via shutdown logic. Exiting container gracefully."
    exit 0
else
    # Otherwise, pass the real error code so standard crash protection still works!
    exit $EXIT_CODE
fi
