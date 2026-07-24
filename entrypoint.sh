#!/bin/bash
# Default fallbacks if Pterodactyl variables are somehow missing
export DMB_FILENAME="${DMB_FILENAME:-game}"
export SERVER_PORT="${SERVER_PORT:-2506}"
export ADDITIONAL_FLAGS="${ADDITIONAL_FLAGS:-}"

# Change to the server files directory
cd /home/container

#echo "Ensuring file permissions are synchronized..."
#chmod -R 755 . 2>/dev/null || true

echo "--------------------------------------------------------"
echo "Starting BYOND Server via Generic Architecture"
echo "Target Binaries : ${DMB_FILENAME}.dmb / ${DMB_FILENAME}.rsc"
echo "Network Port    : ${SERVER_PORT}"
echo "Active Version  : $(DreamDaemon -version | head -n 1)"
echo "--------------------------------------------------------"

# NOTE: no `exec` here — we need the shell to survive DreamDaemon exiting
# so it can inspect the exit code and the clean_shutdown.flag marker below.
DreamDaemon "${DMB_FILENAME}.dmb" "${SERVER_PORT}" -trusted ${ADDITIONAL_FLAGS}
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
