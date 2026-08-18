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

echo "🚀 [Docker] Starting DreamDaemon with command: ${MODIFIED_STARTUP}"

# Run DreamDaemon in the background and trap stop signals to forward them to it.
# This script is PID 1 in the container, and PID 1 silently drops any signal it
# hasn't explicitly handled -- without this, Pterodactyl's stop/restart (which
# sends SIGINT/SIGTERM straight to the container) never reaches DreamDaemon and
# Wings ends up force-killing the container once its stop timeout expires.
eval "${MODIFIED_STARTUP} &"
CHILD_PID=$!

trap 'kill -INT "$CHILD_PID" 2>/dev/null' SIGINT
trap 'kill -TERM "$CHILD_PID" 2>/dev/null' SIGTERM

# wait returns as soon as a trapped signal fires, even though DreamDaemon is
# still shutting down -- keep re-waiting until it has actually exited so we
# don't race ahead and check clean_shutdown.flag before it's been written.
while kill -0 "$CHILD_PID" 2>/dev/null; do
    wait "$CHILD_PID"
    EXIT_CODE=$?
done

# If the game closed cleanly via our shutdown logic, force a clean 0 exit

# code so Pterodactyl/Wings doesn't flag it as a crash.

if [ -f "clean_shutdown.flag" ]; then
    rm -f clean_shutdown.flag
    echo "BYOND closed cleanly via shutdown logic. Exiting container gracefully."
    exit 0
else
    exit $EXIT_CODE
fi
