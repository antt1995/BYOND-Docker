#!/bin/bash

# Change to the server files directory
cd /home/container || exit 1

if [ -f "/opt/tgstation/lib/librust_g.so" ]; then
    echo "⚡ [Docker] Injecting pre-baked rust-g library..."
    ln -sf /opt/tgstation/lib/librust_g.so ./librust_g.so
else
    echo "⚠️ [Docker] Warning: Pre-baked librust_g.so not found in /opt/tgstation/lib/"
fi


echo "--------------------------------------------------------"
echo "Starting BYOND Server via Generic Architecture"
echo "Target Binaries : ${DMB_FILENAME}.dmb / ${DMB_FILENAME}.rsc"
echo "Network Port    : ${SERVER_PORT}"
echo "Active Version  : Build ${BYOND_MAJOR}.${BYOND_MINOR}"
echo "--------------------------------------------------------"
# If Pterodactyl passed an empty STARTUP variable, use a safe default
if [ -z "${STARTUP}" ]; then
    STARTUP="DreamDaemon \${DMB_FILENAME}.dmb \${SERVER_PORT} -close -wg -trusted \${ADDITIONAL_FLAGS}"
fi

MODIFIED_STARTUP=$(echo -e "${STARTUP}" | sed -e 's/{{/${/g' -e 's/}}/}/g')

eval "echo \"🚀 [Docker] Starting DreamDaemon with command: ${MODIFIED_STARTUP}\"; ${MODIFIED_STARTUP}"

EXIT_CODE=$?

# If the game closed cleanly via our shutdown logic, force a clean 0 exit

# code so Pterodactyl/Wings doesn't flag it as a crash.

if [ -f "clean_shutdown.flag" ]; then
    rm -f clean_shutdown.flag
    echo "BYOND closed cleanly via shutdown logic. Exiting container gracefully."
    exit 0
else
    exit $EXIT_CODE
fi
