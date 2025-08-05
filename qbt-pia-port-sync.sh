#!/bin/bash

# --- Configuration ---
# qBittorrent Web UI URL (ensure authentication is handled separately if needed)
QBT_URL="http://localhost:8888/"

# Specify full paths to commands
PIACTL_CMD="/usr/local/bin/piactl"
QBT_CMD="/usr/bin/qbt"
LOGGER_CMD="/usr/bin/logger" # Explicit path for logger

# Script name for logging
SCRIPT_NAME=$(basename "$0")
# --- End Configuration ---

# Function for logging messages to syslog and printing to stderr
log_message() {
    # Use the full path found by 'which logger' or configured above
    "$LOGGER_CMD" -t "$SCRIPT_NAME" "$1"
    echo "$SCRIPT_NAME: $1" >&2 # Print to stderr for console feedback
}

# 1. Get the forwarded port from PIA
log_message "Attempting to get port forward number from PIA..."
PORTNUM=$("$PIACTL_CMD" get portforward)
PIA_EXIT_CODE=$?

# Check if the command returned "Failed"
if [ "$PORTNUM" == "Failed" ]; then
    log_message "WARN: '$PIACTL_CMD get portforward' returned 'Failed'. Attempting disconnect/reconnect cycle."

    log_message "Disconnecting PIA..."
    "$PIACTL_CMD" disconnect
    if [ $? -ne 0 ]; then
        log_message "ERROR: Failed to execute '$PIACTL_CMD disconnect'. Proceeding to connect anyway."
        # Don't exit here, maybe connect will fix it
    fi

    # Add a small delay before reconnecting
    log_message "Waiting 5 seconds before reconnecting..."
    sleep 5

    log_message "Connecting PIA..."
    "$PIACTL_CMD" connect
    CONNECT_EXIT_CODE=$?
    if [ $CONNECT_EXIT_CODE -ne 0 ]; then
        log_message "ERROR: Failed to execute '$PIACTL_CMD connect'. Exit code: $CONNECT_EXIT_CODE"
        exit 1 # Exit if connect fails
    fi

    # Add a delay to allow connection and port forwarding to establish
    log_message "Waiting 10 seconds for connection and port forward assignment..."
    sleep 10

    log_message "Retrying to get port forward number from PIA..."
    PORTNUM=$("$PIACTL_CMD" get portforward)
    PIA_EXIT_CODE=$? # Update exit code after retry
fi

# --- Post-Retry Checks ---
# 1a. Check piactl exit code again
if [ $PIA_EXIT_CODE -ne 0 ]; then
    log_message "ERROR: Failed to execute '$PIACTL_CMD get portforward' (after potential retry). Exit code: $PIA_EXIT_CODE"
    exit 1
fi

# 1b. Check for empty result again
if [ -z "$PORTNUM" ]; then
    log_message "ERROR: '$PIACTL_CMD get portforward' returned an empty string (after potential retry)."
    exit 1
fi

# 1c. Check for "Failed" result again
if [ "$PORTNUM" == "Failed" ]; then
    log_message "ERROR: '$PIACTL_CMD get portforward' still returned 'Failed' after disconnect/reconnect cycle."
    exit 1
fi

# 2. Validate the port number (basic check: is it an integer between 1 and 65535?)
if ! [[ "$PORTNUM" =~ ^[0-9]+$ ]] || [ "$PORTNUM" -lt 1 ] || [ "$PORTNUM" -gt 65535 ]; then
    log_message "ERROR: Acquired value '$PORTNUM' is not a valid port number (1-65535) (after potential retry)."
    exit 1
fi

log_message "Port number acquired: $PORTNUM"

# 3. Update port in qBittorrent
log_message "Attempting to update qBittorrent listening port to $PORTNUM via $QBT_URL..."
if ! "$QBT_CMD" server settings connection --listen-port "$PORTNUM" --url "$QBT_URL"; then
    QBT_EXIT_CODE=$?
    log_message "ERROR: Failed to update qBittorrent port using '$QBT_CMD'. Exit code: $QBT_EXIT_CODE. Check if qBittorrent is running and WebUI is accessible at $QBT_URL."
    exit 1
fi

log_message "Successfully updated qBittorrent listening port to $PORTNUM."
log_message "Script completed successfully."

exit 0